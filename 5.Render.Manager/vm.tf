#########################################################################
# Virtual Machines (https://learn.microsoft.com/azure/virtual-machines) #
#########################################################################

variable virtualMachines {
  type = list(object({
    enable = bool
    name   = string
    size   = string
    image = object({
      resourceGroupName = string
      galleryName       = string
      definitionName    = string
      versionId         = string
      plan = object({
        publisher = string
        product   = string
        name      = string
      })
    })
    network = object({
      subnetName = string
      acceleration = object({
        enable = bool
      })
      locationEdge = object({
        enable = bool
      })
      staticIpAddress = string
    })
    operatingSystem = object({
      type = string
      disk = object({
        storageType = string
        cachingType = string
        sizeGB      = number
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
      custom = object({
        enable   = bool
        name     = string
        fileName = string
        parameters = object({
          autoScale = object({
            enable = bool
          })
        })
      })
      monitor = object({
        enable = bool
        name   = string
      })
    })
  }))
}

locals {
  virtualMachines = [
    for virtualMachine in var.virtualMachines : merge(virtualMachine, {
      image = merge(virtualMachine.image, {
        plan = {
          publisher = try(data.terraform_remote_state.image.outputs.linuxPlan.publisher, virtualMachine.image.plan.publisher)
          product   = try(data.terraform_remote_state.image.outputs.linuxPlan.offer, virtualMachine.image.plan.product)
          name      = try(data.terraform_remote_state.image.outputs.linuxPlan.sku, virtualMachine.image.plan.name)
        }
      })
      network = merge(virtualMachine.network, {
        subnetId = "${virtualMachine.network.locationEdge.enable ? data.azurerm_virtual_network.studio.id : data.azurerm_virtual_network.studio_region.id}/subnets/${var.existingNetwork.enable ? var.existingNetwork.subnetName : virtualMachine.network.subnetName}"
      })
      adminLogin = merge(virtualMachine.adminLogin, {
        userName     = virtualMachine.adminLogin.userName != "" || !module.global.keyVault.enable ? virtualMachine.adminLogin.userName : data.azurerm_key_vault_secret.admin_username[0].value
        userPassword = virtualMachine.adminLogin.userPassword != "" || !module.global.keyVault.enable ? virtualMachine.adminLogin.userPassword : data.azurerm_key_vault_secret.admin_password[0].value
      })
    })
  ]
}

resource azurerm_network_interface scheduler {
  for_each = {
    for virtualMachine in local.virtualMachines : virtualMachine.name => virtualMachine if virtualMachine.enable
  }
  name                = each.value.name
  resource_group_name = azurerm_resource_group.scheduler.name
  location            = module.global.resourceLocation.edgeZone.enable ? module.global.resourceLocation.edgeZone.regionName : azurerm_resource_group.scheduler.location
  edge_zone           = module.global.resourceLocation.edgeZone.enable ? module.global.resourceLocation.edgeZone.name : null
  ip_configuration {
    name                          = "ipConfig"
    subnet_id                     = "${data.azurerm_virtual_network.studio.id}/subnets/${var.existingNetwork.enable ? var.existingNetwork.subnetName : each.value.network.subnetName}"
    private_ip_address            = each.value.network.staticIpAddress != "" ? each.value.network.staticIpAddress : null
    private_ip_address_allocation = each.value.network.staticIpAddress != "" ? "Static" : "Dynamic"
  }
  enable_accelerated_networking = each.value.network.acceleration.enable
}

resource azurerm_linux_virtual_machine scheduler {
  for_each = {
    for virtualMachine in local.virtualMachines : virtualMachine.name => virtualMachine if virtualMachine.enable && lower(virtualMachine.operatingSystem.type) == "linux"
  }
  name                            = each.value.name
  resource_group_name             = azurerm_resource_group.scheduler.name
  location                        = module.global.resourceLocation.edgeZone.enable ? module.global.resourceLocation.edgeZone.regionName : azurerm_resource_group.scheduler.location
  edge_zone                       = module.global.resourceLocation.edgeZone.enable ? module.global.resourceLocation.edgeZone.name : null
  source_image_id                 = "/subscriptions/${data.azurerm_client_config.studio.subscription_id}/resourceGroups/${each.value.image.resourceGroupName}/providers/Microsoft.Compute/galleries/${each.value.image.galleryName}/images/${each.value.image.definitionName}/versions/${each.value.image.versionId}"
  size                            = each.value.size
  admin_username                  = each.value.adminLogin.userName
  admin_password                  = each.value.adminLogin.userPassword
  disable_password_authentication = each.value.adminLogin.passwordAuth.disable
  network_interface_ids = [
    "${azurerm_resource_group.scheduler.id}/providers/Microsoft.Network/networkInterfaces/${each.value.name}"
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
    for_each = each.value.image.plan.publisher != "" ? [1] : []
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
    azurerm_network_interface.scheduler
  ]
}

resource azurerm_virtual_machine_extension initialize_linux {
  for_each = {
    for virtualMachine in local.virtualMachines : virtualMachine.name => virtualMachine if virtualMachine.enable && virtualMachine.extension.custom.enable && lower(virtualMachine.operatingSystem.type) == "linux"
  }
  name                       = each.value.extension.custom.name
  type                       = "CustomScript"
  publisher                  = "Microsoft.Azure.Extensions"
  type_handler_version       = "2.1"
  automatic_upgrade_enabled  = false
  auto_upgrade_minor_version = true
  virtual_machine_id         = "${azurerm_resource_group.scheduler.id}/providers/Microsoft.Compute/virtualMachines/${each.value.name}"
  protected_settings = jsonencode({
    script = base64encode(
      templatefile(each.value.extension.custom.fileName, merge(each.value.extension.custom.parameters, {}))
    )
  })
  depends_on = [
    azurerm_linux_virtual_machine.scheduler
  ]
}

resource azurerm_virtual_machine_extension monitor_linux {
  for_each = {
    for virtualMachine in local.virtualMachines : virtualMachine.name => virtualMachine if virtualMachine.enable && lower(virtualMachine.operatingSystem.type) == "linux" && module.global.monitor.enable && virtualMachine.extension.monitor.enable
  }
  name                       = each.value.extension.monitor.name
  type                       = "AzureMonitorLinuxAgent"
  publisher                  = "Microsoft.Azure.Monitor"
  type_handler_version       = module.global.monitor.agentVersion.linux
  automatic_upgrade_enabled  = true
  auto_upgrade_minor_version = true
  virtual_machine_id         = "${azurerm_resource_group.scheduler.id}/providers/Microsoft.Compute/virtualMachines/${each.value.name}"
  settings = jsonencode({
    authentication = {
      managedIdentity = {
        identifier-name  = "mi_res_id"
        identifier-value = data.azurerm_user_assigned_identity.studio.id
      }
    }
  })
  depends_on = [
    azurerm_virtual_machine_extension.initialize_linux
  ]
}

resource azurerm_monitor_data_collection_rule_association scheduler_linux {
  for_each = {
    for virtualMachine in local.virtualMachines : virtualMachine.name => virtualMachine if virtualMachine.enable && lower(virtualMachine.operatingSystem.type) == "linux" && module.global.monitor.enable && virtualMachine.extension.monitor.enable
  }
  target_resource_id          = azurerm_linux_virtual_machine.scheduler[each.value.name].id
  data_collection_endpoint_id = data.azurerm_monitor_data_collection_endpoint.studio[0].id
}

resource azurerm_windows_virtual_machine scheduler {
  for_each = {
    for virtualMachine in local.virtualMachines : virtualMachine.name => virtualMachine if virtualMachine.enable && lower(virtualMachine.operatingSystem.type) == "windows"
  }
  name                = each.value.name
  resource_group_name = azurerm_resource_group.scheduler.name
  location            = module.global.resourceLocation.edgeZone.enable ? module.global.resourceLocation.edgeZone.regionName : azurerm_resource_group.scheduler.location
  edge_zone           = module.global.resourceLocation.edgeZone.enable ? module.global.resourceLocation.edgeZone.name : null
  source_image_id     = "/subscriptions/${data.azurerm_client_config.studio.subscription_id}/resourceGroups/${each.value.image.resourceGroupName}/providers/Microsoft.Compute/galleries/${each.value.image.galleryName}/images/${each.value.image.definitionName}/versions/${each.value.image.versionId}"
  size                = each.value.size
  admin_username      = each.value.adminLogin.userName
  admin_password      = each.value.adminLogin.userPassword
  network_interface_ids = [
    "${azurerm_resource_group.scheduler.id}/providers/Microsoft.Network/networkInterfaces/${each.value.name}"
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
    azurerm_network_interface.scheduler
  ]
}

resource azurerm_virtual_machine_extension initialize_windows {
  for_each = {
    for virtualMachine in local.virtualMachines : virtualMachine.name => virtualMachine if virtualMachine.enable && virtualMachine.extension.custom.enable && lower(virtualMachine.operatingSystem.type) == "windows"
  }
  name                       = each.value.extension.custom.name
  type                       = "CustomScriptExtension"
  publisher                  = "Microsoft.Compute"
  type_handler_version       = "1.10"
  automatic_upgrade_enabled  = false
  auto_upgrade_minor_version = true
  virtual_machine_id         = "${azurerm_resource_group.scheduler.id}/providers/Microsoft.Compute/virtualMachines/${each.value.name}"
  protected_settings = jsonencode({
    commandToExecute = "PowerShell -ExecutionPolicy Unrestricted -EncodedCommand ${textencodebase64(
      templatefile(each.value.extension.custom.fileName, merge(each.value.extension.custom.parameters, {
        adminPassword   = each.value.adminLogin.userPassword
        activeDirectory = var.activeDirectory
      })), "UTF-16LE"
    )}"
  })
  depends_on = [
    azurerm_windows_virtual_machine.scheduler
  ]
}

resource azurerm_virtual_machine_extension monitor_windows {
  for_each = {
    for virtualMachine in local.virtualMachines : virtualMachine.name => virtualMachine if virtualMachine.enable && lower(virtualMachine.operatingSystem.type) == "windows" && virtualMachine.extension.monitor.enable
  }
  name                       = each.value.extension.monitor.name
  type                       = "AzureMonitorWindowsAgent"
  publisher                  = "Microsoft.Azure.Monitor"
  type_handler_version       = module.global.monitor.agentVersion.windows
  automatic_upgrade_enabled  = true
  auto_upgrade_minor_version = true
  virtual_machine_id         = "${azurerm_resource_group.scheduler.id}/providers/Microsoft.Compute/virtualMachines/${each.value.name}"
  settings = jsonencode({
    authentication = {
      managedIdentity = {
        identifier-name  = "mi_res_id"
        identifier-value = data.azurerm_user_assigned_identity.studio.id
      }
    }
  })
  depends_on = [
    azurerm_virtual_machine_extension.initialize_windows
  ]
}

resource azurerm_monitor_data_collection_rule_association scheduler_windows {
  for_each = {
    for virtualMachine in local.virtualMachines : virtualMachine.name => virtualMachine if virtualMachine.enable && lower(virtualMachine.operatingSystem.type) == "windows" && module.global.monitor.enable && virtualMachine.extension.monitor.enable
  }
  target_resource_id          = azurerm_windows_virtual_machine.scheduler[each.value.name].id
  data_collection_endpoint_id = data.azurerm_monitor_data_collection_endpoint.studio[0].id
}
