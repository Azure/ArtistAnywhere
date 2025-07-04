######################################################################################################
# Virtual Machine Scale Sets (https://learn.microsoft.com/azure/virtual-machine-scale-sets/overview) #
######################################################################################################

variable vmScaleSets {
  type = list(object({
    enable = bool
    name   = string
    machine = object({
      namePrefix = string
      size       = string
      count      = number
      image = object({
        versionId         = string
        galleryName       = string
        definitionName    = string
        resourceGroupName = string
      })
      bootDiagnostics = object({
        enable = bool
      })
    })
    network = object({
      acceleration = object({
        enable = bool
      })
    })
    osDisk = object({
      type        = string
      storageType = string
      cachingMode = string
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
    })
    monitor = object({
      enable = bool
      metric = object({
        category = string
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

data azurerm_location main {
  location = data.azurerm_virtual_network.main.location
}

data azurerm_virtual_machine_scale_set main {
  for_each = {
    for vmScaleSet in local.vmScaleSets : vmScaleSet.name => vmScaleSet if !vmScaleSet.flexMode.enable
  }
  name                = each.value.name
  resource_group_name = azurerm_resource_group.cluster.name
  depends_on = [
    azurerm_linux_virtual_machine_scale_set.cluster,
    azurerm_windows_virtual_machine_scale_set.cluster
  ]
}

data azurerm_orchestrated_virtual_machine_scale_set main {
  for_each = {
    for vmScaleSet in local.vmScaleSets : vmScaleSet.name => vmScaleSet if vmScaleSet.flexMode.enable
  }
  name                = each.value.name
  resource_group_name = azurerm_resource_group.cluster.name
  depends_on = [
    azurerm_orchestrated_virtual_machine_scale_set.cluster
  ]
}

locals {
  vmScaleSets = [
    for vmScaleSet in var.vmScaleSets : merge(vmScaleSet, {
      location = data.azurerm_virtual_network.main.location
      edgeZone = var.virtualNetwork.edgeZoneName != "" ? var.virtualNetwork.edgeZoneName : null
      network = merge(vmScaleSet.network, {
        subnetId = "${data.azurerm_virtual_network.main.id}/subnets/${var.virtualNetwork.subnetName}"
      })
      adminLogin = merge(vmScaleSet.adminLogin, {
        userName     = vmScaleSet.adminLogin.userName != "" ? vmScaleSet.adminLogin.userName : data.azurerm_key_vault_secret.admin_username.value
        userPassword = vmScaleSet.adminLogin.userPassword != "" ? vmScaleSet.adminLogin.userPassword : data.azurerm_key_vault_secret.admin_password.value
        sshKeyPublic = vmScaleSet.adminLogin.sshKeyPublic != "" ? vmScaleSet.adminLogin.sshKeyPublic : data.azurerm_key_vault_secret.ssh_key_public.value
      })
    }) if vmScaleSet.enable
  ]
}

resource azurerm_linux_virtual_machine_scale_set cluster {
  for_each = {
    for vmScaleSet in local.vmScaleSets : vmScaleSet.name => vmScaleSet if lower(vmScaleSet.osDisk.type) == "linux" && !vmScaleSet.flexMode.enable
  }
  name                            = each.value.name
  computer_name_prefix            = each.value.machine.namePrefix == "" ? null : each.value.machine.namePrefix
  resource_group_name             = azurerm_resource_group.cluster.name
  location                        = each.value.location
  edge_zone                       = each.value.edgeZone
  sku                             = each.value.machine.size
  instances                       = each.value.machine.count
  source_image_id                 = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${each.value.machine.image.resourceGroupName}/providers/Microsoft.Compute/galleries/${each.value.machine.image.galleryName}/images/${each.value.machine.image.definitionName}/versions/${each.value.machine.image.versionId}"
  admin_username                  = each.value.adminLogin.userName
  admin_password                  = each.value.adminLogin.userPassword
  disable_password_authentication = each.value.adminLogin.passwordAuth.disable
  priority                        = each.value.spot.enable ? "Spot" : "Regular"
  eviction_policy                 = each.value.spot.enable ? each.value.spot.evictionPolicy : null
  zones                           = var.virtualNetwork.edgeZoneName == "" && each.value.availabilityZones.enable && length(data.azurerm_location.main.zone_mappings) > 0 ? data.azurerm_location.main.zone_mappings[*].logical_zone : null
  zone_balance                    = var.virtualNetwork.edgeZoneName == "" && each.value.availabilityZones.enable && length(data.azurerm_location.main.zone_mappings) > 0 ? each.value.availabilityZones.evenDistribution.enable : null
  single_placement_group          = false
  overprovision                   = false
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.main.id
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
    caching              = each.value.osDisk.cachingMode
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
      type                       = "CustomScript"
      publisher                  = "Microsoft.Azure.Extensions"
      type_handler_version       = data.azurerm_app_configuration_keys.main.items[index(data.azurerm_app_configuration_keys.main.items[*].key, data.terraform_remote_state.foundation.outputs.appConfig.key.scriptExtensionLinux)].value
      automatic_upgrade_enabled  = false
      auto_upgrade_minor_version = true
      protected_settings = jsonencode({
        script = base64encode(
          templatefile(each.value.extension.custom.fileName, merge(each.value.extension.custom.parameters, {
            fileSystem = module.config.fileSystem.linux
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
  dynamic boot_diagnostics {
    for_each = each.value.machine.bootDiagnostics.enable ? [1] : []
    content {
      storage_account_uri = null
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

resource azurerm_monitor_diagnostic_setting cluster_monitor_linux {
  for_each = {
    for vmScaleSet in local.vmScaleSets : vmScaleSet.name => vmScaleSet if lower(vmScaleSet.osDisk.type) == "linux" && !vmScaleSet.flexMode.enable
  }
  name                       = each.value.name
  target_resource_id         = "${azurerm_resource_group.cluster.id}/providers/Microsoft.Compute/virtualMachineScaleSets/${each.value.name}"
  log_analytics_workspace_id = data.terraform_remote_state.foundation.outputs.monitor.logAnalytics.id
  enabled_metric {
    category = each.value.monitor.metric.category
  }
  depends_on = [
    azurerm_linux_virtual_machine_scale_set.cluster
  ]
}

resource azurerm_windows_virtual_machine_scale_set cluster {
  for_each = {
    for vmScaleSet in local.vmScaleSets : vmScaleSet.name => vmScaleSet if lower(vmScaleSet.osDisk.type) == "windows" && !vmScaleSet.flexMode.enable
  }
  name                   = each.value.name
  computer_name_prefix   = each.value.machine.namePrefix == "" ? null : each.value.machine.namePrefix
  resource_group_name    = azurerm_resource_group.cluster.name
  location               = each.value.location
  edge_zone              = each.value.edgeZone
  sku                    = each.value.machine.size
  instances              = each.value.machine.count
  source_image_id        = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${each.value.machine.image.resourceGroupName}/providers/Microsoft.Compute/galleries/${each.value.machine.image.galleryName}/images/${each.value.machine.image.definitionName}/versions/${each.value.machine.image.versionId}"
  admin_username         = each.value.adminLogin.userName
  admin_password         = each.value.adminLogin.userPassword
  priority               = each.value.spot.enable ? "Spot" : "Regular"
  eviction_policy        = each.value.spot.enable ? each.value.spot.evictionPolicy : null
  zones                  = var.virtualNetwork.edgeZoneName == "" && each.value.availabilityZones.enable && length(data.azurerm_location.main.zone_mappings) > 0 ? data.azurerm_location.main.zone_mappings[*].logical_zone : null
  zone_balance           = var.virtualNetwork.edgeZoneName == "" && each.value.availabilityZones.enable && length(data.azurerm_location.main.zone_mappings) > 0 ? each.value.availabilityZones.evenDistribution.enable : null
  single_placement_group = false
  overprovision          = false
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.main.id
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
    caching              = each.value.osDisk.cachingMode
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
      type_handler_version       = data.azurerm_app_configuration_keys.main.items[index(data.azurerm_app_configuration_keys.main.items[*].key, data.terraform_remote_state.foundation.outputs.appConfig.key.scriptExtensionWindows)].value
      automatic_upgrade_enabled  = false
      auto_upgrade_minor_version = true
      protected_settings = jsonencode({
        commandToExecute = "PowerShell -ExecutionPolicy Unrestricted -EncodedCommand ${textencodebase64(
          templatefile(each.value.extension.custom.fileName, merge(each.value.extension.custom.parameters, {
            activeDirectory = local.activeDirectory
            fileSystem      = module.config.fileSystem.windows
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
  dynamic boot_diagnostics {
    for_each = each.value.machine.bootDiagnostics.enable ? [1] : []
    content {
      storage_account_uri = null
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

resource azurerm_monitor_diagnostic_setting cluster_monitor_windows {
  for_each = {
    for vmScaleSet in local.vmScaleSets : vmScaleSet.name => vmScaleSet if lower(vmScaleSet.osDisk.type) == "windows" && !vmScaleSet.flexMode.enable
  }
  name                       = each.value.name
  target_resource_id         = "${azurerm_resource_group.cluster.id}/providers/Microsoft.Compute/virtualMachineScaleSets/${each.value.name}"
  log_analytics_workspace_id = data.terraform_remote_state.foundation.outputs.monitor.logAnalytics.id
  enabled_metric {
    category = each.value.monitor.metric.category
  }
  depends_on = [
    azurerm_windows_virtual_machine_scale_set.cluster
  ]
}

resource azurerm_orchestrated_virtual_machine_scale_set cluster {
  for_each = {
    for vmScaleSet in local.vmScaleSets : vmScaleSet.name => vmScaleSet if vmScaleSet.flexMode.enable
  }
  name                        = each.value.name
  resource_group_name         = azurerm_resource_group.cluster.name
  location                    = each.value.location
  # edge_zone                   = each.value.edgeZone
  sku_name                    = each.value.machine.size
  instances                   = each.value.machine.count
  source_image_id             = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${each.value.machine.image.resourceGroupName}/providers/Microsoft.Compute/galleries/${each.value.machine.image.galleryName}/images/${each.value.machine.image.definitionName}/versions/${each.value.machine.image.versionId}"
  priority                    = each.value.spot.enable ? "Spot" : "Regular"
  eviction_policy             = each.value.spot.enable ? each.value.spot.evictionPolicy : null
  zones                       = var.virtualNetwork.edgeZoneName == "" && each.value.availabilityZones.enable && length(data.azurerm_location.main.zone_mappings) > 0 ? data.azurerm_location.main.zone_mappings[*].logical_zone : null
  zone_balance                = var.virtualNetwork.edgeZoneName == "" && each.value.availabilityZones.enable && length(data.azurerm_location.main.zone_mappings) > 0 ? each.value.availabilityZones.evenDistribution.enable : null
  platform_fault_domain_count = each.value.availabilityZones.enable || each.value.spot.enable ? 1 : 3
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.main.id
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
    caching              = each.value.osDisk.cachingMode
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
  dynamic extension { # Custom Linux
    for_each = each.value.extension.custom.enable && lower(each.value.osDisk.type) != "windows" ? [1] : []
    content {
      name                               = each.value.extension.custom.name
      type                               = "CustomScript"
      publisher                          = "Microsoft.Azure.Extensions"
      type_handler_version               = data.azurerm_app_configuration_keys.main.items[index(data.azurerm_app_configuration_keys.main.items[*].key, data.terraform_remote_state.foundation.outputs.appConfig.key.scriptExtensionLinux)].value
      auto_upgrade_minor_version_enabled = true
      protected_settings = jsonencode({
        script = base64encode(
          templatefile(each.value.extension.custom.fileName, merge(each.value.extension.custom.parameters, {
            fileSystem = module.config.fileSystem.linux
          }))
        )
      })
    }
  }
  dynamic extension { # Custom Windows
    for_each = each.value.extension.custom.enable && lower(each.value.osDisk.type) == "windows" ? [1] : []
    content {
      name                               = each.value.extension.custom.name
      type                               = "CustomScriptExtension"
      publisher                          = "Microsoft.Compute"
      type_handler_version               = data.azurerm_app_configuration_keys.main.items[index(data.azurerm_app_configuration_keys.main.items[*].key, data.terraform_remote_state.foundation.outputs.appConfig.key.scriptExtensionWindows)].value
      auto_upgrade_minor_version_enabled = true
      protected_settings = jsonencode({
        commandToExecute = "PowerShell -ExecutionPolicy Unrestricted -EncodedCommand ${textencodebase64(
          templatefile(each.value.extension.custom.fileName, merge(each.value.extension.custom.parameters, {
            activeDirectory = local.activeDirectory
            fileSystem      = module.config.fileSystem.windows
          })), "UTF-16LE"
        )}"
      })
    }
  }
  dynamic extension { # Health
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
  dynamic boot_diagnostics {
    for_each = each.value.machine.bootDiagnostics.enable ? [1] : []
    content {
      storage_account_uri = null
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

resource azurerm_monitor_diagnostic_setting cluster_monitor {
  for_each = {
    for vmScaleSet in local.vmScaleSets : vmScaleSet.name => vmScaleSet if vmScaleSet.flexMode.enable
  }
  name                       = each.value.name
  target_resource_id         = "${azurerm_resource_group.cluster.id}/providers/Microsoft.Compute/virtualMachineScaleSets/${each.value.name}"
  log_analytics_workspace_id = data.terraform_remote_state.foundation.outputs.monitor.logAnalytics.id
  enabled_metric {
    category = each.value.monitor.metric.category
  }
  depends_on = [
    azurerm_orchestrated_virtual_machine_scale_set.cluster
  ]
}
