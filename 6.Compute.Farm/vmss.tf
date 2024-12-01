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
    })
    network = object({
      subnetName = string
      acceleration = object({
        enable = bool
      })
      locationExtended = object({
        enable = bool
      })
    })
    osDisk = object({
      type        = string
      storageType = string
      cachingType = string
      sizeGB      = number
      ephemeral = object({
        enable    = bool
        placement = string
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
    extension = object({
      custom = object({
        enable   = bool
        name     = string
        fileName = string
        parameters = object({
          terminateNotification = object({
            enable       = bool
            delayTimeout = string
          })
        })
      })
      health = object({
        enable      = bool
        name        = string
        protocol    = string
        port        = number
        requestPath = string
      })
      monitor = object({
        enable = bool
        name   = string
      })
    })
    adminLogin = object({
      userName     = string
      userPassword = string
      sshKeyPublic = string
      passwordAuth = object({
        disable = bool
      })
    })
    availabilityZones = object({
      enable  = bool
      evenDistribution = object({
        enable = bool
      })
    })
    flexMode = object({
      enable = bool
    })
  }))
}

data azurerm_location region {
  location = module.global.resourceLocation.regionName
}

locals {
  virtualMachineScaleSets = [
    for virtualMachineScaleSet in var.virtualMachineScaleSets : merge(virtualMachineScaleSet, {
      resourceLocation = {
        regionName       = virtualMachineScaleSet.network.locationExtended.enable ? module.global.resourceLocation.extendedZone.regionName : module.global.resourceLocation.regionName
        extendedZoneName = virtualMachineScaleSet.network.locationExtended.enable ? module.global.resourceLocation.extendedZone.name : null
      }
      machine = merge(virtualMachineScaleSet.machine, {
        image = merge(virtualMachineScaleSet.machine.image, {
          plan = {
            publisher = try(data.terraform_remote_state.image.outputs.linux.publisher, virtualMachineScaleSet.machine.image.plan.publisher)
            product   = try(data.terraform_remote_state.image.outputs.linux.offer, virtualMachineScaleSet.machine.image.plan.product)
            name      = try(data.terraform_remote_state.image.outputs.linux.sku, virtualMachineScaleSet.machine.image.plan.name)
          }
        })
      })
      network = merge(virtualMachineScaleSet.network, {
        subnetId = "${virtualMachineScaleSet.network.locationExtended.enable ? data.azurerm_virtual_network.studio_extended.id : data.azurerm_virtual_network.studio.id}/subnets/${var.existingNetwork.enable ? var.existingNetwork.subnetName : virtualMachineScaleSet.network.subnetName}"
      })
      adminLogin = merge(virtualMachineScaleSet.adminLogin, {
        userName     = virtualMachineScaleSet.adminLogin.userName != "" ? virtualMachineScaleSet.adminLogin.userName : data.azurerm_key_vault_secret.admin_username.value
        userPassword = virtualMachineScaleSet.adminLogin.userPassword != "" ? virtualMachineScaleSet.adminLogin.userPassword : data.azurerm_key_vault_secret.admin_password.value
        sshKeyPublic = virtualMachineScaleSet.adminLogin.sshKeyPublic != "" ? virtualMachineScaleSet.adminLogin.sshKeyPublic : data.azurerm_key_vault_secret.ssh_key_public.value
      })
      activeDirectory = merge(var.activeDirectory, {
        adminUsername = var.activeDirectory.adminUsername != "" ? var.activeDirectory.adminUsername : data.azurerm_key_vault_secret.admin_username.value
        adminPassword = var.activeDirectory.adminPassword != "" ? var.activeDirectory.adminPassword : data.azurerm_key_vault_secret.admin_password.value
      })
    }) if virtualMachineScaleSet.enable
  ]
}

resource azurerm_linux_virtual_machine_scale_set farm {
  for_each = {
    for virtualMachineScaleSet in local.virtualMachineScaleSets : virtualMachineScaleSet.name => virtualMachineScaleSet if lower(virtualMachineScaleSet.osDisk.type) == "linux" && !virtualMachineScaleSet.flexMode.enable
  }
  name                            = each.value.name
  computer_name_prefix            = each.value.machine.namePrefix == "" ? null : each.value.machine.namePrefix
  resource_group_name             = azurerm_resource_group.farm.name
  location                        = each.value.resourceLocation.regionName
  edge_zone                       = each.value.resourceLocation.extendedZoneName
  sku                             = each.value.machine.size
  instances                       = each.value.machine.count
  source_image_id                 = "/subscriptions/${module.global.subscriptionId}/resourceGroups/${each.value.machine.image.resourceGroupName}/providers/Microsoft.Compute/galleries/${each.value.machine.image.galleryName}/images/${each.value.machine.image.definitionName}/versions/${each.value.machine.image.versionId}"
  admin_username                  = each.value.adminLogin.userName
  admin_password                  = each.value.adminLogin.userPassword
  disable_password_authentication = each.value.adminLogin.passwordAuth.disable
  priority                        = each.value.spot.enable ? "Spot" : "Regular"
  eviction_policy                 = each.value.spot.enable ? each.value.spot.evictionPolicy : null
  zones                           = each.value.availabilityZones.enable && length(data.azurerm_location.region.zone_mappings) > 0 ? [for i in range(1, length(data.azurerm_location.region.zone_mappings) + 1) : i] : null
  zone_balance                    = each.value.availabilityZones.enable && length(data.azurerm_location.region.zone_mappings) > 0 ? each.value.availabilityZones.evenDistribution.enable : null
  single_placement_group          = false
  overprovision                   = false
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
      subnet_id = each.value.network.subnetId
    }
    enable_accelerated_networking = each.value.network.acceleration.enable
  }
  os_disk {
    storage_account_type = each.value.osDisk.storageType
    caching              = each.value.osDisk.cachingType
    disk_size_gb         = each.value.osDisk.sizeGB > 0 ? each.value.osDisk.sizeGB : null
    dynamic diff_disk_settings {
      for_each = each.value.osDisk.ephemeral.enable ? [1] : []
      content {
        option    = "Local"
        placement = each.value.osDisk.ephemeral.placement
      }
    }
  }
  dynamic plan {
    for_each = each.value.machine.image.plan.publisher != "" ? [1] : []
    content {
      publisher = each.value.machine.image.plan.publisher
      product   = each.value.machine.image.plan.product
      name      = each.value.machine.image.plan.name
    }
  }
  dynamic extension {
    for_each = each.value.extension.custom.enable ? [1] : []
    content {
      name                       = each.value.extension.custom.name
      type                       = "CustomScript"
      publisher                  = "Microsoft.Azure.Extensions"
      type_handler_version       = module.global.version.script_extension_linux
      automatic_upgrade_enabled  = false
      auto_upgrade_minor_version = true
      protected_settings = jsonencode({
        script = base64encode(
          templatefile(each.value.extension.custom.fileName, merge(each.value.extension.custom.parameters, {
            fileSystem = module.global.fileSystem.linux
          }))
        )
      })
    }
  }
  dynamic extension {
    for_each = each.value.extension.health.enable ? [1] : []
    content {
      name                       = each.value.extension.health.name
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
    for_each = each.value.extension.monitor.enable ? [1] : []
    content {
      name                       = each.value.extension.monitor.name
      type                       = "AzureMonitorLinuxAgent"
      publisher                  = "Microsoft.Azure.Monitor"
      type_handler_version       = module.global.version.monitor_agent_linux
      automatic_upgrade_enabled  = true
      auto_upgrade_minor_version = true
      settings = jsonencode({
        authentication = {
          managedIdentity = {
            identifier-name  = "mi_res_id"
            identifier-value = data.azurerm_user_assigned_identity.studio.id
          }
        }
      })
    }
  }
  dynamic admin_ssh_key {
    for_each = each.value.adminLogin.sshKeyPublic != "" ? [1] : []
    content {
      username   = each.value.adminLogin.userName
      public_key = each.value.adminLogin.sshKeyPublic
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

resource azurerm_monitor_data_collection_rule_association farm_linux {
  for_each = {
    for virtualMachineScaleSet in local.virtualMachineScaleSets : virtualMachineScaleSet.name => virtualMachineScaleSet if lower(virtualMachineScaleSet.osDisk.type) == "linux" && !virtualMachineScaleSet.flexMode.enable && virtualMachineScaleSet.extension.monitor.enable
  }
  target_resource_id          = azurerm_linux_virtual_machine_scale_set.farm[each.value.name].id
  data_collection_endpoint_id = data.azurerm_monitor_data_collection_endpoint.studio.id
}

resource azurerm_windows_virtual_machine_scale_set farm {
  for_each = {
    for virtualMachineScaleSet in local.virtualMachineScaleSets : virtualMachineScaleSet.name => virtualMachineScaleSet if lower(virtualMachineScaleSet.osDisk.type) == "windows" && !virtualMachineScaleSet.flexMode.enable
  }
  name                   = each.value.name
  computer_name_prefix   = each.value.machine.namePrefix == "" ? null : each.value.machine.namePrefix
  resource_group_name    = azurerm_resource_group.farm.name
  location               = each.value.resourceLocation.regionName
  edge_zone              = each.value.resourceLocation.extendedZoneName
  sku                    = each.value.machine.size
  instances              = each.value.machine.count
  source_image_id        = "/subscriptions/${module.global.subscriptionId}/resourceGroups/${each.value.machine.image.resourceGroupName}/providers/Microsoft.Compute/galleries/${each.value.machine.image.galleryName}/images/${each.value.machine.image.definitionName}/versions/${each.value.machine.image.versionId}"
  admin_username         = each.value.adminLogin.userName
  admin_password         = each.value.adminLogin.userPassword
  priority               = each.value.spot.enable ? "Spot" : "Regular"
  eviction_policy        = each.value.spot.enable ? each.value.spot.evictionPolicy : null
  zones                  = each.value.availabilityZones.enable && length(data.azurerm_location.region.zone_mappings) > 0 ? [for i in range(1, length(data.azurerm_location.region.zone_mappings) + 1) : i] : null
  zone_balance           = each.value.availabilityZones.enable && length(data.azurerm_location.region.zone_mappings) > 0 ? each.value.availabilityZones.evenDistribution.enable : null
  single_placement_group = false
  overprovision          = false
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
      subnet_id = each.value.network.subnetId
    }
    enable_accelerated_networking = each.value.network.acceleration.enable
  }
  os_disk {
    storage_account_type = each.value.osDisk.storageType
    caching              = each.value.osDisk.cachingType
    disk_size_gb         = each.value.osDisk.sizeGB > 0 ? each.value.osDisk.sizeGB : null
    dynamic diff_disk_settings {
      for_each = each.value.osDisk.ephemeral.enable ? [1] : []
      content {
        option    = "Local"
        placement = each.value.osDisk.ephemeral.placement
      }
    }
  }
  dynamic extension {
    for_each = each.value.extension.custom.enable ? [1] : []
    content {
      name                       = each.value.extension.custom.name
      type                       = "CustomScriptExtension"
      publisher                  = "Microsoft.Compute"
      type_handler_version       = module.global.version.script_extension_windows
      automatic_upgrade_enabled  = false
      auto_upgrade_minor_version = true
      protected_settings = jsonencode({
        commandToExecute = "PowerShell -ExecutionPolicy Unrestricted -EncodedCommand ${textencodebase64(
          templatefile(each.value.extension.custom.fileName, merge(each.value.extension.custom.parameters, {
            fileSystem      = module.global.fileSystem.windows
            activeDirectory = each.value.activeDirectory
          })), "UTF-16LE"
        )}"
      })
    }
  }
  dynamic extension {
    for_each = each.value.extension.health.enable ? [1] : []
    content {
      name                       = each.value.extension.health.name
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
    for_each = each.value.extension.monitor.enable ? [1] : []
    content {
      name                       = each.value.extension.monitor.name
      type                       = "AzureMonitorWindowsAgent"
      publisher                  = "Microsoft.Azure.Monitor"
      type_handler_version       = module.global.version.monitor_agent_windows
      automatic_upgrade_enabled  = true
      auto_upgrade_minor_version = true
      settings = jsonencode({
        authentication = {
          managedIdentity = {
            identifier-name  = "mi_res_id"
            identifier-value = data.azurerm_user_assigned_identity.studio.id
          }
        }
      })
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

resource azurerm_monitor_data_collection_rule_association farm_windows {
  for_each = {
    for virtualMachineScaleSet in local.virtualMachineScaleSets : virtualMachineScaleSet.name => virtualMachineScaleSet if lower(virtualMachineScaleSet.osDisk.type) == "windows" && !virtualMachineScaleSet.flexMode.enable && virtualMachineScaleSet.extension.monitor.enable
  }
  target_resource_id          = azurerm_windows_virtual_machine_scale_set.farm[each.value.name].id
  data_collection_endpoint_id = data.azurerm_monitor_data_collection_endpoint.studio.id
}

resource azurerm_orchestrated_virtual_machine_scale_set farm {
  for_each = {
    for virtualMachineScaleSet in local.virtualMachineScaleSets : virtualMachineScaleSet.name => virtualMachineScaleSet if virtualMachineScaleSet.flexMode.enable
  }
  name                        = each.value.name
  resource_group_name         = azurerm_resource_group.farm.name
  location                    = each.value.resourceLocation.regionName
  # edge_zone                   = each.value.resourceLocation.extendedZoneName
  sku_name                    = each.value.machine.size
  instances                   = each.value.machine.count
  source_image_id             = "/subscriptions/${module.global.subscriptionId}/resourceGroups/${each.value.machine.image.resourceGroupName}/providers/Microsoft.Compute/galleries/${each.value.machine.image.galleryName}/images/${each.value.machine.image.definitionName}/versions/${each.value.machine.image.versionId}"
  priority                    = each.value.spot.enable ? "Spot" : "Regular"
  eviction_policy             = each.value.spot.enable ? each.value.spot.evictionPolicy : null
  zones                       = each.value.availabilityZones.enable && length(data.azurerm_location.region.zone_mappings) > 0 ? [for i in range(1, length(data.azurerm_location.region.zone_mappings) + 1) : i] : null
  zone_balance                = each.value.availabilityZones.enable && length(data.azurerm_location.region.zone_mappings) > 0 ? each.value.availabilityZones.evenDistribution.enable : null
  platform_fault_domain_count = each.value.availabilityZones.enable || each.value.spot.enable ? 1 : 3
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
      subnet_id = each.value.network.subnetId
    }
    enable_accelerated_networking = each.value.network.acceleration.enable
  }
  os_disk {
    storage_account_type = each.value.osDisk.storageType
    caching              = each.value.osDisk.cachingType
    disk_size_gb         = each.value.osDisk.sizeGB > 0 ? each.value.osDisk.sizeGB : null
    dynamic diff_disk_settings {
      for_each = each.value.osDisk.ephemeral.enable ? [1] : []
      content {
        option    = "Local"
        placement = each.value.osDisk.ephemeral.placement
      }
    }
  }
  os_profile {
    dynamic linux_configuration {
      for_each = lower(each.value.osDisk.type) == "linux" ? [1] : []
      content {
        computer_name_prefix            = each.value.machine.namePrefix == "" ? null : each.value.machine.namePrefix
        admin_username                  = each.value.adminLogin.userName
        admin_password                  = each.value.adminLogin.userPassword
        disable_password_authentication = each.value.adminLogin.passwordAuth.disable
        dynamic admin_ssh_key {
          for_each = each.value.adminLogin.sshKeyPublic != "" ? [1] : []
          content {
            username   = each.value.adminLogin.userName
            public_key = each.value.adminLogin.sshKeyPublic
          }
        }
      }
    }
    dynamic windows_configuration {
      for_each = lower(each.value.osDisk.type) == "windows" ? [1] : []
      content {
        computer_name_prefix = each.value.machine.namePrefix == "" ? null : each.value.machine.namePrefix
        admin_username       = each.value.adminLogin.userName
        admin_password       = each.value.adminLogin.userPassword
      }
    }
  }
  dynamic plan {
    for_each = lower(each.value.osDisk.type) == "linux" && each.value.machine.image.plan.publisher != "" ? [1] : []
    content {
      publisher = each.value.machine.image.plan.publisher
      product   = each.value.machine.image.plan.product
      name      = each.value.machine.image.plan.name
    }
  }
  dynamic extension {
    for_each = each.value.extension.custom.enable ? [1] : []
    content {
      name                               = each.value.extension.custom.name
      type                               = lower(each.value.osDisk.type) == "windows" ? "CustomScriptExtension" :"CustomScript"
      publisher                          = lower(each.value.osDisk.type) == "windows" ? "Microsoft.Compute" : "Microsoft.Azure.Extensions"
      type_handler_version               = lower(each.value.osDisk.type) == "windows" ? module.global.version.script_extension_windows : module.global.version.script_extension_linux
      auto_upgrade_minor_version_enabled = true
      protected_settings = jsonencode({
        script = lower(each.value.osDisk.type) == "windows" ? null : base64encode(
          templatefile(each.value.extension.custom.fileName, merge(each.value.extension.custom.parameters, {
            fileSystem = module.global.fileSystem.linux
          }))
        )
        commandToExecute = lower(each.value.osDisk.type) == "windows" ? "PowerShell -ExecutionPolicy Unrestricted -EncodedCommand ${textencodebase64(
          templatefile(each.value.extension.custom.fileName, merge(each.value.extension.custom.parameters, {
            fileSystem      = module.global.fileSystem.windows
            activeDirectory = each.value.activeDirectory
          })), "UTF-16LE"
        )}" : null
      })
    }
  }
  dynamic extension {
    for_each = each.value.extension.health.enable ? [1] : []
    content {
      name                               = each.value.extension.health.name
      type                               = lower(each.value.osDisk.type) == "windows" ? "ApplicationHealthWindows" : "ApplicationHealthLinux"
      publisher                          = "Microsoft.ManagedServices"
      type_handler_version               = "1.0"
      auto_upgrade_minor_version_enabled = true
      settings = jsonencode({
        protocol    = each.value.extension.health.protocol
        port        = each.value.extension.health.port
        requestPath = each.value.extension.health.requestPath
      })
    }
  }
  dynamic extension {
    for_each = each.value.extension.monitor.enable ? [1] : []
    content {
      name                               = each.value.extension.monitor.name
      type                               = lower(each.value.osDisk.type) == "windows" ? "AzureMonitorWindowsAgent" : "AzureMonitorLinuxAgent"
      publisher                          = "Microsoft.Azure.Monitor"
      type_handler_version               = lower(each.value.osDisk.type) == "windows" ? module.global.version.monitor_agent_windows : module.global.version.monitor_agent_linux
      auto_upgrade_minor_version_enabled = true
      settings = jsonencode({
        authentication = {
          managedIdentity = {
            identifier-name  = "mi_res_id"
            identifier-value = data.azurerm_user_assigned_identity.studio.id
          }
        }
      })
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

resource azurerm_monitor_data_collection_rule_association farm {
  for_each = {
    for virtualMachineScaleSet in local.virtualMachineScaleSets : virtualMachineScaleSet.name => virtualMachineScaleSet if virtualMachineScaleSet.flexMode.enable && virtualMachineScaleSet.extension.monitor.enable
  }
  target_resource_id          = azurerm_orchestrated_virtual_machine_scale_set.farm[each.value.name].id
  data_collection_endpoint_id = data.azurerm_monitor_data_collection_endpoint.studio.id
}
