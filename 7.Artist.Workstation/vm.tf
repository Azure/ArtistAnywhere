#########################################################################
# Virtual Machines (https://learn.microsoft.com/azure/virtual-machines) #
#########################################################################

variable virtualMachines {
  type = list(object({
    enable = bool
    name   = string
    size   = string
    count  = number
    image = object({
      id   = string
      plan = object({
        enable    = bool
        publisher = string
        product   = string
        name      = string
      })
    })
    operatingSystem = object({
      type = string
      disk = object({
        storageType = string
        cachingType = string
        sizeGB      = number
      })
    })
    network = object({
      subnetName = string
      acceleration = object({
        enable = bool
      })
    })
    adminLogin = object({
      userName     = string
      userPassword = string
      sshPublicKey = string
      passwordAuth = object({
        disable = bool
      })
    })
    extension = object({
      initialize = object({
        enable     = bool
        fileName   = string
        parameters = object({
          pcoipLicenseKey = string
        })
      })
      monitor = object({
        enable = bool
      })
    })
  }))
}

locals {
  fileSystemsLinux = [
    for fileSystem in var.fileSystems.linux : fileSystem if fileSystem.enable
  ]
  fileSystemsWindows = [
    for fileSystem in var.fileSystems.windows : fileSystem if fileSystem.enable
  ]
  virtualMachines = flatten([
    for virtualMachine in var.virtualMachines : [
      for i in range(virtualMachine.count) : merge(virtualMachine, {
        name = "${virtualMachine.name}${i}"
        adminLogin = {
          userName     = virtualMachine.adminLogin.userName != "" ? virtualMachine.adminLogin.userName : data.azurerm_key_vault_secret.admin_username.value
          userPassword = virtualMachine.adminLogin.userPassword != "" ? virtualMachine.adminLogin.userPassword : data.azurerm_key_vault_secret.admin_password.value
          sshPublicKey = virtualMachine.adminLogin.sshPublicKey
          passwordAuth = {
            disable = virtualMachine.adminLogin.passwordAuth.disable
          }
        }
        activeDirectory = {
          enable           = var.activeDirectory.enable
          domainName       = var.activeDirectory.domainName
          domainServerName = var.activeDirectory.domainServerName
          orgUnitPath      = var.activeDirectory.orgUnitPath
          adminUsername    = var.activeDirectory.adminUsername != "" ? var.activeDirectory.adminUsername : data.azurerm_key_vault_secret.admin_username.value
          adminPassword    = var.activeDirectory.adminPassword != "" ? var.activeDirectory.adminPassword : data.azurerm_key_vault_secret.admin_password.value
        }
      })
    ]
  ])
}

resource azurerm_network_interface workstation {
  for_each = {
    for virtualMachine in local.virtualMachines : virtualMachine.name => virtualMachine if virtualMachine.enable
  }
  name                = each.value.name
  resource_group_name = azurerm_resource_group.workstation.name
  location            = azurerm_resource_group.workstation.location
  ip_configuration {
    name                          = "ipConfig"
    subnet_id                     = "${data.azurerm_virtual_network.studio.id}/subnets/${var.existingNetwork.enable ? var.existingNetwork.subnetName : each.value.network.subnetName}"
    private_ip_address_allocation = "Dynamic"
  }
  enable_accelerated_networking = each.value.network.acceleration.enable
}

resource azurerm_linux_virtual_machine workstation {
  for_each = {
    for virtualMachine in local.virtualMachines : virtualMachine.name => virtualMachine if virtualMachine.enable && virtualMachine.operatingSystem.type == "Linux"
  }
  name                            = each.value.name
  resource_group_name             = azurerm_resource_group.workstation.name
  location                        = azurerm_resource_group.workstation.location
  size                            = each.value.size
  source_image_id                 = each.value.image.id
  admin_username                  = each.value.adminLogin.userName
  admin_password                  = each.value.adminLogin.userPassword
  disable_password_authentication = each.value.adminLogin.passwordAuth.disable
  network_interface_ids = [
    "${azurerm_resource_group.workstation.id}/providers/Microsoft.Network/networkInterfaces/${each.value.name}"
  ]
  os_disk {
    storage_account_type = each.value.operatingSystem.disk.storageType
    caching              = each.value.operatingSystem.disk.cachingType
    disk_size_gb         = each.value.operatingSystem.disk.sizeGB > 0 ? each.value.operatingSystem.disk.sizeGB : null
  }
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  dynamic plan {
    for_each = each.value.image.plan.enable ? [1] : []
    content {
      publisher = each.value.image.plan.publisher
      product   = each.value.image.plan.product
      name      = each.value.image.plan.name
    }
  }
  dynamic admin_ssh_key {
    for_each = each.value.adminLogin.sshPublicKey != "" ? [1] : []
    content {
      username   = each.value.adminLogin.userName
      public_key = each.value.adminLogin.sshPublicKey
    }
  }
  depends_on = [
    azurerm_network_interface.workstation
  ]
}

resource azurerm_virtual_machine_extension monitor_linux {
  for_each = {
    for virtualMachine in local.virtualMachines : virtualMachine.name => virtualMachine if virtualMachine.enable && virtualMachine.extension.monitor.enable && virtualMachine.operatingSystem.type == "Linux" && module.global.monitor.enable
  }
  name                       = "Monitor"
  type                       = "AzureMonitorLinuxAgent"
  publisher                  = "Microsoft.Azure.Monitor"
  type_handler_version       = "1.29"
  automatic_upgrade_enabled  = true
  auto_upgrade_minor_version = true
  virtual_machine_id         = "${azurerm_resource_group.workstation.id}/providers/Microsoft.Compute/virtualMachines/${each.value.name}"
  settings = jsonencode({
    workspaceId = data.azurerm_log_analytics_workspace.monitor[0].workspace_id
  })
  protected_settings = jsonencode({
    workspaceKey = data.azurerm_log_analytics_workspace.monitor[0].primary_shared_key
  })
  depends_on = [
    azurerm_linux_virtual_machine.workstation
  ]
}

resource azurerm_virtual_machine_extension initialize_linux {
  for_each = {
    for virtualMachine in local.virtualMachines : virtualMachine.name => virtualMachine if virtualMachine.enable && virtualMachine.extension.initialize.enable && virtualMachine.operatingSystem.type == "Linux"
  }
  name                       = "Initialize"
  type                       = "CustomScript"
  publisher                  = "Microsoft.Azure.Extensions"
  type_handler_version       = "2.1"
  automatic_upgrade_enabled  = false
  auto_upgrade_minor_version = true
  virtual_machine_id         = "${azurerm_resource_group.workstation.id}/providers/Microsoft.Compute/virtualMachines/${each.value.name}"
  protected_settings = jsonencode({
    script = base64encode(
      templatefile(each.value.extension.initialize.fileName, merge(each.value.extension.initialize.parameters, {
        fileSystems      = local.fileSystemsLinux
        databaseUsername = data.azurerm_key_vault_secret.database_username.value
        databasePassword = data.azurerm_key_vault_secret.database_password.value
      }))
    )
  })
  depends_on = [
    azurerm_virtual_machine_extension.monitor_linux
  ]
}

resource azurerm_windows_virtual_machine workstation {
  for_each = {
    for virtualMachine in local.virtualMachines : virtualMachine.name => virtualMachine if virtualMachine.enable && virtualMachine.operatingSystem.type == "Windows"
  }
  name                = each.value.name
  resource_group_name = azurerm_resource_group.workstation.name
  location            = azurerm_resource_group.workstation.location
  size                = each.value.size
  source_image_id     = each.value.image.id
  admin_username      = each.value.adminLogin.userName
  admin_password      = each.value.adminLogin.userPassword
  network_interface_ids = [
    "${azurerm_resource_group.workstation.id}/providers/Microsoft.Network/networkInterfaces/${each.value.name}"
  ]
  os_disk {
    storage_account_type = each.value.operatingSystem.disk.storageType
    caching              = each.value.operatingSystem.disk.cachingType
    disk_size_gb         = each.value.operatingSystem.disk.sizeGB > 0 ? each.value.operatingSystem.disk.sizeGB : null
  }
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  depends_on = [
    azurerm_network_interface.workstation
  ]
}

resource azurerm_virtual_machine_extension monitor_windows {
  for_each = {
    for virtualMachine in local.virtualMachines : virtualMachine.name => virtualMachine if virtualMachine.enable && virtualMachine.extension.monitor.enable && virtualMachine.operatingSystem.type == "Windows" && module.global.monitor.enable
  }
  name                       = "Monitor"
  type                       = "AzureMonitorWindowsAgent"
  publisher                  = "Microsoft.Azure.Monitor"
  type_handler_version       = "1.23"
  automatic_upgrade_enabled  = true
  auto_upgrade_minor_version = true
  virtual_machine_id         = "${azurerm_resource_group.workstation.id}/providers/Microsoft.Compute/virtualMachines/${each.value.name}"
  settings = jsonencode({
    workspaceId = data.azurerm_log_analytics_workspace.monitor[0].workspace_id
  })
  protected_settings = jsonencode({
    workspaceKey = data.azurerm_log_analytics_workspace.monitor[0].primary_shared_key
  })
  depends_on = [
    azurerm_windows_virtual_machine.workstation
  ]
}

resource azurerm_virtual_machine_extension initialize_windows {
  for_each = {
    for virtualMachine in local.virtualMachines : virtualMachine.name => virtualMachine if virtualMachine.enable && virtualMachine.extension.initialize.enable && virtualMachine.operatingSystem.type == "Windows"
  }
  name                       = "Initialize"
  type                       = "CustomScriptExtension"
  publisher                  = "Microsoft.Compute"
  type_handler_version       = "1.10"
  automatic_upgrade_enabled  = false
  auto_upgrade_minor_version = true
  virtual_machine_id         = "${azurerm_resource_group.workstation.id}/providers/Microsoft.Compute/virtualMachines/${each.value.name}"
  protected_settings = jsonencode({
    commandToExecute = "PowerShell -ExecutionPolicy Unrestricted -EncodedCommand ${textencodebase64(
      templatefile(each.value.extension.initialize.fileName, merge(each.value.extension.initialize.parameters, {
        fileSystems     = local.fileSystemsWindows
        activeDirectory = each.value.activeDirectory
      })), "UTF-16LE"
    )}"
  })
  depends_on = [
    azurerm_virtual_machine_extension.monitor_windows
  ]
}
