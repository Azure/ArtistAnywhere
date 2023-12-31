######################################################################################################
# Virtual Machine Scale Sets (https://learn.microsoft.com/azure/virtual-machine-scale-sets/overview) #
######################################################################################################

variable virtualMachineScaleSets {
  type = list(object({
    enable = bool
    name = object({
      prefix = string
      suffix = object({
        enable = bool
      })
    })
    machine = object({
      size  = string
      count = number
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
    spot = object({
      enable         = bool
      evictionPolicy = string
      tryRestore = object({
        enable  = bool
        timeout = string
      })
    })
    network = object({
      acceleration = object({
        enable = bool
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
          terminateNotification = object({
            enable       = bool
            delayTimeout = string
          })
        })
      })
      health = object({
        enable      = bool
        protocol    = string
        port        = number
        requestPath = string
      })
      monitor = object({
        enable = bool
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
    for fileSystem in module.farm.fileSystems.linux : fileSystem if fileSystem.enable
  ]
  fileSystemsWindows = [
    for fileSystem in module.farm.fileSystems.windows : fileSystem if fileSystem.enable
  ]
  virtualMachineScaleSets = [
    for virtualMachineScaleSet in var.virtualMachineScaleSets : merge(virtualMachineScaleSet, {
      name = {
        prefix = virtualMachineScaleSet.name.prefix
        value  = virtualMachineScaleSet.name.suffix.enable ? "${virtualMachineScaleSet.name.prefix}_${replace(plantimestamp(), ":", "-")}" : virtualMachineScaleSet.name.prefix
      }
      adminLogin = {
        userName     = virtualMachineScaleSet.adminLogin.userName != "" ? virtualMachineScaleSet.adminLogin.userName : try(data.azurerm_key_vault_secret.admin_username[0].value, "")
        userPassword = virtualMachineScaleSet.adminLogin.userPassword != "" ? virtualMachineScaleSet.adminLogin.userPassword : try(data.azurerm_key_vault_secret.admin_password[0].value, "")
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
        adminUsername    = var.activeDirectory.adminUsername != "" ? var.activeDirectory.adminUsername : try(data.azurerm_key_vault_secret.admin_username[0].value, "")
        adminPassword    = var.activeDirectory.adminPassword != "" ? var.activeDirectory.adminPassword : try(data.azurerm_key_vault_secret.admin_password[0].value, "")
      }
    }) if virtualMachineScaleSet.enable
  ]
}

resource azurerm_linux_virtual_machine_scale_set farm {
  for_each = {
    for virtualMachineScaleSet in local.virtualMachineScaleSets : virtualMachineScaleSet.name.value => virtualMachineScaleSet if !virtualMachineScaleSet.flexibleOrchestration.enable && virtualMachineScaleSet.operatingSystem.type == "Linux"
  }
  name                            = each.value.name.value
  computer_name_prefix            = each.value.name.prefix
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
    name    = each.value.name.prefix
    primary = true
    ip_configuration {
      name      = "ipConfig"
      primary   = true
      subnet_id = data.azurerm_subnet.farm.id
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
  dynamic plan {
    for_each = each.value.machine.image.plan.enable ? [1] : []
    content {
      publisher = each.value.machine.image.plan.publisher
      product   = each.value.machine.image.plan.product
      name      = each.value.machine.image.plan.name
    }
  }
  dynamic spot_restore {
    for_each = each.value.spot.tryRestore.enable ? [1] : []
    content {
      enabled = each.value.spot.tryRestore.enable
      timeout = each.value.spot.tryRestore.timeout
    }
  }
  dynamic admin_ssh_key {
    for_each = each.value.adminLogin.sshPublicKey != "" ? [1] : []
    content {
      username   = each.value.adminLogin.userName
      public_key = each.value.adminLogin.sshPublicKey
    }
  }
  dynamic extension {
    for_each = each.value.extension.initialize.enable ? [1] : []
    content {
      name                       = "Initialize"
      type                       = "CustomScript"
      publisher                  = "Microsoft.Azure.Extensions"
      type_handler_version       = "2.1"
      automatic_upgrade_enabled  = false
      auto_upgrade_minor_version = true
      settings = jsonencode({
        script = "${base64encode(
          templatefile(each.value.extension.initialize.fileName, merge(each.value.extension.initialize.parameters, {
            fileSystems     = local.fileSystemsLinux,
            activeDirectory = each.value.activeDirectory
          }))
        )}"
      })
    }
  }
  dynamic extension {
    for_each = each.value.extension.health.enable ? [1] : []
    content {
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
  }
  dynamic extension {
    for_each = each.value.extension.monitor.enable && module.global.monitor.enable ? [1] : []
    content {
      name                       = "Monitor"
      type                       = "AzureMonitorLinuxAgent"
      publisher                  = "Microsoft.Azure.Monitor"
      type_handler_version       = "1.21"
      automatic_upgrade_enabled  = true
      auto_upgrade_minor_version = true
      settings = jsonencode({
        workspaceId = data.azurerm_log_analytics_workspace.monitor[0].workspace_id
      })
      protected_settings = jsonencode({
        workspaceKey = data.azurerm_log_analytics_workspace.monitor[0].primary_shared_key
      })
    }
  }
  dynamic termination_notification {
    for_each = each.value.extension.initialize.parameters.terminateNotification.enable ? [1] : []
    content {
      enabled = each.value.extension.initialize.parameters.terminateNotification.enable
      timeout = each.value.extension.initialize.parameters.terminateNotification.delayTimeout
    }
  }
}

resource azurerm_windows_virtual_machine_scale_set farm {
  for_each = {
    for virtualMachineScaleSet in local.virtualMachineScaleSets : virtualMachineScaleSet.name.value => virtualMachineScaleSet if !virtualMachineScaleSet.flexibleOrchestration.enable && virtualMachineScaleSet.operatingSystem.type == "Windows"
  }
  name                   = each.value.name.value
  computer_name_prefix   = each.value.name.prefix
  resource_group_name    = azurerm_resource_group.farm.name
  location               = azurerm_resource_group.farm.location
  sku                    = each.value.machine.size
  instances              = each.value.machine.count
  source_image_id        = each.value.machine.image.id
  admin_username         = each.value.adminLogin.userName
  admin_password         = each.value.adminLogin.userPassword
  priority               = each.value.spot.enable ? "Spot" : "Regular"
  eviction_policy        = each.value.spot.enable ? each.value.spot.evictionPolicy : null
  custom_data            = base64encode(templatefile("../0.Global.Foundation/functions.ps1", {}))
  single_placement_group = false
  overprovision          = false
  network_interface {
    name    = each.value.name.prefix
    primary = true
    ip_configuration {
      name      = "ipConfig"
      primary   = true
      subnet_id = data.azurerm_subnet.farm.id
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
  dynamic spot_restore {
    for_each = each.value.spot.tryRestore.enable ? [1] : []
    content {
      enabled = each.value.spot.tryRestore.enable
      timeout = each.value.spot.tryRestore.timeout
    }
  }
  dynamic extension {
    for_each = each.value.extension.initialize.enable ? [1] : []
    content {
      name                       = "Initialize"
      type                       = "CustomScriptExtension"
      publisher                  = "Microsoft.Compute"
      type_handler_version       = "1.10"
      automatic_upgrade_enabled  = false
      auto_upgrade_minor_version = true
      settings = jsonencode({
        commandToExecute = "PowerShell -ExecutionPolicy Unrestricted -EncodedCommand ${textencodebase64(
          templatefile(each.value.extension.initialize.fileName, merge(each.value.extension.initialize.parameters, {
            fileSystems     = local.fileSystemsWindows,
            activeDirectory = each.value.activeDirectory
          })), "UTF-16LE"
        )}"
      })
    }
  }
  dynamic extension {
    for_each = each.value.extension.health.enable ? [1] : []
    content {
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
  }
  dynamic extension {
    for_each = each.value.extension.monitor.enable && module.global.monitor.enable ? [1] : []
    content {
      name                       = "Monitor"
      type                       = "AzureMonitorWindowsAgent"
      publisher                  = "Microsoft.Azure.Monitor"
      type_handler_version       = "1.7"
      automatic_upgrade_enabled  = true
      auto_upgrade_minor_version = true
      settings = jsonencode({
        workspaceId = data.azurerm_log_analytics_workspace.monitor[0].workspace_id
      })
      protected_settings = jsonencode({
        workspaceKey = data.azurerm_log_analytics_workspace.monitor[0].primary_shared_key
      })
    }
  }
  dynamic termination_notification {
    for_each = each.value.extension.initialize.parameters.terminateNotification.enable ? [1] : []
    content {
      enabled = each.value.extension.initialize.parameters.terminateNotification.enable
      timeout = each.value.extension.initialize.parameters.terminateNotification.delayTimeout
    }
  }
}

resource azurerm_orchestrated_virtual_machine_scale_set farm {
  for_each = {
    for virtualMachineScaleSet in local.virtualMachineScaleSets : virtualMachineScaleSet.name.value => virtualMachineScaleSet if virtualMachineScaleSet.flexibleOrchestration.enable
  }
  name                        = each.value.name.value
  resource_group_name         = azurerm_resource_group.farm.name
  location                    = azurerm_resource_group.farm.location
  sku_name                    = each.value.machine.size
  instances                   = each.value.machine.count
  source_image_id             = each.value.machine.image.id
  priority                    = each.value.spot.enable ? "Spot" : "Regular"
  eviction_policy             = each.value.spot.enable ? each.value.spot.evictionPolicy : null
  platform_fault_domain_count = each.value.faultDomainCount
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  network_interface {
    name    = each.value.name.prefix
    primary = true
    ip_configuration {
      name      = "ipConfig"
      primary   = true
      subnet_id = data.azurerm_subnet.farm.id
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
    custom_data = each.value.operatingSystem.type == "Windows" ? base64encode(templatefile("../0.Global.Foundation/functions.ps1", {})) : null
    dynamic linux_configuration {
      for_each = each.value.operatingSystem.type == "Linux" ? [1] : []
      content {
        computer_name_prefix            = each.value.name.prefix
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
        computer_name_prefix = each.value.name.prefix
        admin_username       = each.value.adminLogin.userName
        admin_password       = each.value.adminLogin.userPassword
      }
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
  dynamic extension {
    for_each = each.value.extension.initialize.enable && each.value.operatingSystem.type == "Linux" ? [1] : []
    content {
      name                 = "Initialize"
      type                 = "CustomScript"
      publisher            = "Microsoft.Azure.Extensions"
      type_handler_version = "2.1"
      settings = jsonencode({
        script = "${base64encode(
          templatefile(each.value.extension.initialize.fileName, merge(each.value.extension.initialize.parameters, {
            fileSystems     = local.fileSystemsLinux,
            activeDirectory = each.value.activeDirectory
          }))
        )}"
      })
    }
  }
  dynamic extension {
    for_each = each.value.extension.initialize.enable && each.value.operatingSystem.type == "Windows" ? [1] : []
    content {
      name                 = "Initialize"
      type                 = "CustomScriptExtension"
      publisher            = "Microsoft.Compute"
      type_handler_version = "1.10"
      settings = jsonencode({
        commandToExecute = "PowerShell -ExecutionPolicy Unrestricted -EncodedCommand ${textencodebase64(
          templatefile(each.value.extension.initialize.fileName, merge(each.value.extension.initialize.parameters, {
            fileSystems     = local.fileSystemsWindows,
            activeDirectory = each.value.activeDirectory
          })), "UTF-16LE"
        )}"
      })
    }
  }
  dynamic extension {
    for_each = each.value.extension.health.enable ? [1] : []
    content {
      name                 = "Health"
      type                 = each.value.operatingSystem.type == "Windows" ? "ApplicationHealthWindows" : "ApplicationHealthLinux"
      publisher            = "Microsoft.ManagedServices"
      type_handler_version = "1.0"
      settings = jsonencode({
        protocol    = each.value.extension.health.protocol
        port        = each.value.extension.health.port
        requestPath = each.value.extension.health.requestPath
      })
    }
  }
  dynamic extension {
    for_each = each.value.extension.monitor.enable && module.global.monitor.enable ? [1] : []
    content {
      name                 = "Monitor"
      type                 = each.value.operatingSystem.type == "Windows" ? "AzureMonitorWindowsAgent" : "AzureMonitorLinuxAgent"
      publisher            = "Microsoft.Azure.Monitor"
      type_handler_version = each.value.operatingSystem.type == "Windows" ? "1.7" : "1.21"
      settings = jsonencode({
        workspaceId = data.azurerm_log_analytics_workspace.monitor[0].workspace_id
      })
      protected_settings = jsonencode({
        workspaceKey = data.azurerm_log_analytics_workspace.monitor[0].primary_shared_key
      })
    }
  }
  dynamic termination_notification {
    for_each = each.value.extension.initialize.parameters.terminateNotification.enable ? [1] : []
    content {
      enabled = each.value.extension.initialize.parameters.terminateNotification.enable
      timeout = each.value.extension.initialize.parameters.terminateNotification.delayTimeout
    }
  }
}

output virtualMachineScaleSetsLinux {
  value = [
    for virtualMachineScaleSet in azurerm_linux_virtual_machine_scale_set.farm : {
      name              = virtualMachineScaleSet.name
      resourceGroupName = virtualMachineScaleSet.resource_group_name
    }
  ]
}

output virtualMachineScaleSetsWindows {
  value = [
    for virtualMachineScaleSet in azurerm_windows_virtual_machine_scale_set.farm : {
      name              = virtualMachineScaleSet.name
      resourceGroupName = virtualMachineScaleSet.resource_group_name
    }
  ]
}

output virtualMachineScaleSetsFlexible {
  value = [
    for virtualMachineScaleSet in azurerm_orchestrated_virtual_machine_scale_set.farm : {
      name              = virtualMachineScaleSet.name
      resourceGroupName = virtualMachineScaleSet.resource_group_name
    }
  ]
}
