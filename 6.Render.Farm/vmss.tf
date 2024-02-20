######################################################################################################
# Virtual Machine Scale Sets (https://learn.microsoft.com/azure/virtual-machine-scale-sets/overview) #
######################################################################################################

variable virtualMachineScaleSets {
  type = list(object({
    enable = bool
    name   = string
    machine = object({
      namePrefix = string
      size       = string
      count      = number
      image = object({
        id   = string
        plan = object({
          enable    = bool
          publisher = string
          product   = string
          name      = string
        })
      })
    })
    operatingSystem = object({
      type = string
      disk = object({
        storageType = string
        cachingType = string
        sizeGB      = number
        ephemeral = object({
          enable    = bool
          placement = string
        })
      })
    })
    spot = object({
      enable         = bool
      evictionPolicy = string
      tryRestore = object({
        enable  = bool
        timeout = string
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
      health = object({
        protocol    = string
        port        = number
        requestPath = string
      })
      custom = object({
        enable     = bool
        name       = string
        fileName   = string
        parameters = object({
          terminateNotification = object({
            enable       = bool
            delayTimeout = string
          })
        })
      })
    })
    flexibleOrchestration = object({
      enable           = bool
      faultDomainCount = number
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
  virtualMachineScaleSets = [
    for virtualMachineScaleSet in var.virtualMachineScaleSets : merge(virtualMachineScaleSet, {
      adminLogin = {
        userName     = virtualMachineScaleSet.adminLogin.userName != "" ? virtualMachineScaleSet.adminLogin.userName : data.azurerm_key_vault_secret.admin_username.value
        userPassword = virtualMachineScaleSet.adminLogin.userPassword != "" ? virtualMachineScaleSet.adminLogin.userPassword : data.azurerm_key_vault_secret.admin_password.value
        sshPublicKey = virtualMachineScaleSet.adminLogin.sshPublicKey
        passwordAuth = {
          disable = virtualMachineScaleSet.adminLogin.passwordAuth.disable
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
    }) if virtualMachineScaleSet.enable
  ]
}

resource azurerm_linux_virtual_machine_scale_set farm {
  for_each = {
    for virtualMachineScaleSet in local.virtualMachineScaleSets : virtualMachineScaleSet.name => virtualMachineScaleSet if virtualMachineScaleSet.operatingSystem.type == "Linux" && !virtualMachineScaleSet.flexibleOrchestration.enable
  }
  name                            = each.value.name
  computer_name_prefix            = each.value.machine.namePrefix == "" ? null : each.value.machine.namePrefix
  resource_group_name             = azurerm_resource_group.farm.name
  location                        = azurerm_resource_group.farm.location
  sku                             = each.value.machine.size
  instances                       = each.value.machine.count
  source_image_id                 = each.value.machine.image.id
  admin_username                  = each.value.adminLogin.userName
  admin_password                  = each.value.adminLogin.userPassword
  disable_password_authentication = each.value.adminLogin.passwordAuth.disable
  priority                        = each.value.spot.enable ? "Spot" : "Regular"
  eviction_policy                 = each.value.spot.enable ? each.value.spot.evictionPolicy : null
  single_placement_group          = false
  overprovision                   = false
  network_interface {
    name    = each.value.name
    primary = true
    ip_configuration {
      name      = "ipConfig"
      primary   = true
      subnet_id = "${data.azurerm_virtual_network.studio.id}/subnets/${var.existingNetwork.enable ? var.existingNetwork.subnetName : each.value.network.subnetName}"
    }
    enable_accelerated_networking = each.value.network.acceleration.enable
  }
  os_disk {
    storage_account_type = each.value.operatingSystem.disk.storageType
    caching              = each.value.operatingSystem.disk.cachingType
    disk_size_gb         = each.value.operatingSystem.disk.sizeGB > 0 ? each.value.operatingSystem.disk.sizeGB : null
    dynamic diff_disk_settings {
      for_each = each.value.operatingSystem.disk.ephemeral.enable ? [1] : []
      content {
        option    = "Local"
        placement = each.value.operatingSystem.disk.ephemeral.placement
      }
    }
  }
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  extension {
    name                       = "Health"
    type                       = "ApplicationHealthLinux"
    publisher                  = "Microsoft.ManagedServices"
    type_handler_version       = "1.0"
    automatic_upgrade_enabled  = true
    auto_upgrade_minor_version = true
    settings = jsonencode({
      protocol    = each.value.extension.health.protocol
      port        = each.value.extension.health.port
      requestPath = each.value.extension.health.requestPath
    })
  }
  # extension {
  #   name                       = "Monitor"
  #   type                       = "AzureMonitorLinuxAgent"
  #   publisher                  = "Microsoft.Azure.Monitor"
  #   type_handler_version       = module.global.monitor.agentVersion.linux
  #   automatic_upgrade_enabled  = true
  #   auto_upgrade_minor_version = true
  #   settings = jsonencode({
  #     workspaceId = data.azurerm_log_analytics_workspace.monitor.workspace_id
  #   })
  #   protected_settings = jsonencode({
  #     workspaceKey = data.azurerm_log_analytics_workspace.monitor.primary_shared_key
  #   })
  #   provision_after_extensions = [
  #     "Health"
  #   ]
  # }
  dynamic extension {
    for_each = each.value.extension.custom.enable ? [1] : []
    content {
      name                       = each.value.extension.custom.name
      type                       = "CustomScript"
      publisher                  = "Microsoft.Azure.Extensions"
      type_handler_version       = "2.1"
      automatic_upgrade_enabled  = false
      auto_upgrade_minor_version = true
      protected_settings = jsonencode({
        script = base64encode(
          templatefile(each.value.extension.custom.fileName, merge(each.value.extension.custom.parameters, {
            fileSystems = local.fileSystemsLinux
          }))
        )
      })
      provision_after_extensions = [
        "Health"
      ]
    }
  }
  dynamic plan {
    for_each = each.value.machine.image.plan.enable ? [1] : []
    content {
      publisher = each.value.machine.image.plan.publisher
      product   = each.value.machine.image.plan.product
      name      = each.value.machine.image.plan.name
    }
  }
  dynamic admin_ssh_key {
    for_each = each.value.adminLogin.sshPublicKey != "" ? [1] : []
    content {
      username   = each.value.adminLogin.userName
      public_key = each.value.adminLogin.sshPublicKey
    }
  }
  dynamic termination_notification {
    for_each = each.value.extension.custom.parameters.terminateNotification.enable ? [1] : []
    content {
      enabled = each.value.extension.custom.parameters.terminateNotification.enable
      timeout = each.value.extension.custom.parameters.terminateNotification.delayTimeout
    }
  }
  dynamic spot_restore {
    for_each = each.value.spot.tryRestore.enable ? [1] : []
    content {
      enabled = each.value.spot.tryRestore.enable
      timeout = each.value.spot.tryRestore.timeout
    }
  }
}

resource azurerm_windows_virtual_machine_scale_set farm {
  for_each = {
    for virtualMachineScaleSet in local.virtualMachineScaleSets : virtualMachineScaleSet.name => virtualMachineScaleSet if virtualMachineScaleSet.operatingSystem.type == "Windows" && !virtualMachineScaleSet.flexibleOrchestration.enable
  }
  name                   = each.value.name
  computer_name_prefix   = each.value.machine.namePrefix == "" ? null : each.value.machine.namePrefix
  resource_group_name    = azurerm_resource_group.farm.name
  location               = azurerm_resource_group.farm.location
  sku                    = each.value.machine.size
  instances              = each.value.machine.count
  source_image_id        = each.value.machine.image.id
  admin_username         = each.value.adminLogin.userName
  admin_password         = each.value.adminLogin.userPassword
  priority               = each.value.spot.enable ? "Spot" : "Regular"
  eviction_policy        = each.value.spot.enable ? each.value.spot.evictionPolicy : null
  single_placement_group = false
  overprovision          = false
  network_interface {
    name    = each.value.name
    primary = true
    ip_configuration {
      name      = "ipConfig"
      primary   = true
      subnet_id = "${data.azurerm_virtual_network.studio.id}/subnets/${var.existingNetwork.enable ? var.existingNetwork.subnetName : each.value.network.subnetName}"
    }
    enable_accelerated_networking = each.value.network.acceleration.enable
  }
  os_disk {
    storage_account_type = each.value.operatingSystem.disk.storageType
    caching              = each.value.operatingSystem.disk.cachingType
    disk_size_gb         = each.value.operatingSystem.disk.sizeGB > 0 ? each.value.operatingSystem.disk.sizeGB : null
    dynamic diff_disk_settings {
      for_each = each.value.operatingSystem.disk.ephemeral.enable ? [1] : []
      content {
        option    = "Local"
        placement = each.value.operatingSystem.disk.ephemeral.placement
      }
    }
  }
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  extension {
    name                       = "Health"
    type                       = "ApplicationHealthWindows"
    publisher                  = "Microsoft.ManagedServices"
    type_handler_version       = "1.0"
    automatic_upgrade_enabled  = true
    auto_upgrade_minor_version = true
    settings = jsonencode({
      protocol    = each.value.extension.health.protocol
      port        = each.value.extension.health.port
      requestPath = each.value.extension.health.requestPath
    })
  }
  extension {
    name                       = "Monitor"
    type                       = "AzureMonitorWindowsAgent"
    publisher                  = "Microsoft.Azure.Monitor"
    type_handler_version       = module.global.monitor.agentVersion.windows
    automatic_upgrade_enabled  = true
    auto_upgrade_minor_version = true
    settings = jsonencode({
      workspaceId = data.azurerm_log_analytics_workspace.monitor.workspace_id
    })
    protected_settings = jsonencode({
      workspaceKey = data.azurerm_log_analytics_workspace.monitor.primary_shared_key
    })
    provision_after_extensions = [
      "Health"
    ]
  }
  dynamic extension {
    for_each = each.value.extension.custom.enable ? [1] : []
    content {
      name                       = each.value.extension.custom.name
      type                       = "CustomScriptExtension"
      publisher                  = "Microsoft.Compute"
      type_handler_version       = "1.10"
      automatic_upgrade_enabled  = false
      auto_upgrade_minor_version = true
      protected_settings = jsonencode({
        commandToExecute = "PowerShell -ExecutionPolicy Unrestricted -EncodedCommand ${textencodebase64(
          templatefile(each.value.extension.custom.fileName, merge(each.value.extension.custom.parameters, {
            fileSystems     = local.fileSystemsWindows
            activeDirectory = each.value.activeDirectory
          })), "UTF-16LE"
        )}"
      })
      provision_after_extensions = [
        "Monitor"
      ]
    }
  }
  dynamic termination_notification {
    for_each = each.value.extension.custom.parameters.terminateNotification.enable ? [1] : []
    content {
      enabled = each.value.extension.custom.parameters.terminateNotification.enable
      timeout = each.value.extension.custom.parameters.terminateNotification.delayTimeout
    }
  }
  dynamic spot_restore {
    for_each = each.value.spot.tryRestore.enable ? [1] : []
    content {
      enabled = each.value.spot.tryRestore.enable
      timeout = each.value.spot.tryRestore.timeout
    }
  }
}

resource azurerm_orchestrated_virtual_machine_scale_set farm {
  for_each = {
    for virtualMachineScaleSet in local.virtualMachineScaleSets : virtualMachineScaleSet.name => virtualMachineScaleSet if virtualMachineScaleSet.flexibleOrchestration.enable
  }
  name                        = each.value.name
  resource_group_name         = azurerm_resource_group.farm.name
  location                    = azurerm_resource_group.farm.location
  sku_name                    = each.value.machine.size
  instances                   = each.value.machine.count
  source_image_id             = each.value.machine.image.id
  priority                    = each.value.spot.enable ? "Spot" : "Regular"
  eviction_policy             = each.value.spot.enable ? each.value.spot.evictionPolicy : null
  platform_fault_domain_count = each.value.flexibleOrchestration.faultDomainCount
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  network_interface {
    name    = each.value.name
    primary = true
    ip_configuration {
      name      = "ipConfig"
      primary   = true
      subnet_id = "${data.azurerm_virtual_network.studio.id}/subnets/${var.existingNetwork.enable ? var.existingNetwork.subnetName : each.value.network.subnetName}"
    }
    enable_accelerated_networking = each.value.network.acceleration.enable
  }
  os_disk {
    storage_account_type = each.value.operatingSystem.disk.storageType
    caching              = each.value.operatingSystem.disk.cachingType
    disk_size_gb         = each.value.operatingSystem.disk.sizeGB > 0 ? each.value.operatingSystem.disk.sizeGB : null
    dynamic diff_disk_settings {
      for_each = each.value.operatingSystem.disk.ephemeral.enable ? [1] : []
      content {
        option    = "Local"
        placement = each.value.operatingSystem.disk.ephemeral.placement
      }
    }
  }
  os_profile {
    dynamic linux_configuration {
      for_each = each.value.operatingSystem.type == "Linux" ? [1] : []
      content {
        computer_name_prefix            = each.value.machine.namePrefix == "" ? null : each.value.machine.namePrefix
        admin_username                  = each.value.adminLogin.userName
        admin_password                  = each.value.adminLogin.userPassword
        disable_password_authentication = each.value.adminLogin.passwordAuth.disable
        dynamic admin_ssh_key {
          for_each = each.value.adminLogin.sshPublicKey != "" ? [1] : []
          content {
            username   = each.value.adminLogin.userName
            public_key = each.value.adminLogin.sshPublicKey
          }
        }
      }
    }
    dynamic windows_configuration {
      for_each = each.value.operatingSystem.type == "Windows" ? [1] : []
      content {
        computer_name_prefix = each.value.machine.namePrefix == "" ? null : each.value.machine.namePrefix
        admin_username       = each.value.adminLogin.userName
        admin_password       = each.value.adminLogin.userPassword
      }
    }
  }
  extension {
    name                               = "Health"
    type                               = each.value.operatingSystem.type == "Windows" ? "ApplicationHealthWindows" : "ApplicationHealthLinux"
    publisher                          = "Microsoft.ManagedServices"
    type_handler_version               = "1.0"
    auto_upgrade_minor_version_enabled = true
    settings = jsonencode({
      protocol    = each.value.extension.health.protocol
      port        = each.value.extension.health.port
      requestPath = each.value.extension.health.requestPath
    })
  }
  extension {
    name                               = "Monitor"
    type                               = each.value.operatingSystem.type == "Windows" ? "AzureMonitorWindowsAgent" : "AzureMonitorLinuxAgent"
    publisher                          = "Microsoft.Azure.Monitor"
    type_handler_version               = each.value.operatingSystem.type == "Windows" ? module.global.monitor.agentVersion.windows : module.global.monitor.agentVersion.linux
    auto_upgrade_minor_version_enabled = true
    settings = jsonencode({
      workspaceId = data.azurerm_log_analytics_workspace.monitor.workspace_id
    })
    protected_settings = jsonencode({
      workspaceKey = data.azurerm_log_analytics_workspace.monitor.primary_shared_key
    })
    # extensions_to_provision_after_vm_creation = [
    #   "Health"
    # ]
  }
  dynamic extension {
    for_each = each.value.extension.custom.enable ? [1] : []
    content {
      name                               = each.value.extension.custom.name
      type                               = each.value.operatingSystem.type == "Windows" ? "CustomScriptExtension" :"CustomScript"
      publisher                          = each.value.operatingSystem.type == "Windows" ? "Microsoft.Compute" : "Microsoft.Azure.Extensions"
      type_handler_version               = each.value.operatingSystem.type == "Windows" ? "1.10" : "2.1"
      auto_upgrade_minor_version_enabled = true
      protected_settings = jsonencode({
        script = each.value.operatingSystem.type == "Windows" ? null : base64encode(
          templatefile(each.value.extension.custom.fileName, merge(each.value.extension.custom.parameters, {
            fileSystems = local.fileSystemsLinux
          }))
        )
        commandToExecute = each.value.operatingSystem.type == "Windows" ? "PowerShell -ExecutionPolicy Unrestricted -EncodedCommand ${textencodebase64(
          templatefile(each.value.extension.custom.fileName, merge(each.value.extension.custom.parameters, {
            fileSystems     = local.fileSystemsWindows
            activeDirectory = each.value.activeDirectory
          })), "UTF-16LE"
        )}" : null
      })
      # extensions_to_provision_after_vm_creation = [
      #   "Monitor"
      # ]
    }
  }
  dynamic plan {
    for_each = each.value.machine.image.plan.enable ? [1] : []
    content {
      publisher = each.value.machine.image.plan.publisher
      product   = each.value.machine.image.plan.product
      name      = each.value.machine.image.plan.name
    }
  }
  dynamic termination_notification {
    for_each = each.value.extension.custom.parameters.terminateNotification.enable ? [1] : []
    content {
      enabled = each.value.extension.custom.parameters.terminateNotification.enable
      timeout = each.value.extension.custom.parameters.terminateNotification.delayTimeout
    }
  }
}
