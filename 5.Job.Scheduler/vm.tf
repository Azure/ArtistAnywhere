#########################################################################
# Virtual Machines (https://learn.microsoft.com/azure/virtual-machines) #
#########################################################################

variable virtualMachines {
  type = list(object({
    enable = bool
    name   = string
    size   = string
    image = object({
      versionId         = string
      galleryName       = string
      definitionName    = string
      resourceGroupName = string
    })
    osDisk = object({
      type        = string
      storageType = string
      cachingMode = string
      sizeGB      = number
    })
    network = object({
      acceleration = object({
        enable = bool
      })
      locationExtended = object({
        enable = bool
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
            resourceGroupName        = string
            jobSchedulerName         = string
            computeClusterName       = string
            computeClusterNodeLimit  = number
            workerIdleDeleteSeconds  = number
            jobWaitThresholdSeconds  = number
            detectionIntervalSeconds = number
          })
        })
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
  }))
}

data azurerm_resource_group virtual_network_extended {
  count = var.virtualNetworkExtended.enable ? 1 : 0
  name  = data.azurerm_virtual_network.studio_extended[0].resource_group_name
}

data azapi_resource virtual_network_extended {
  count     = var.virtualNetworkExtended.enable ? 1 : 0
  name      = data.azurerm_virtual_network.studio_extended[0].name
  parent_id = data.azurerm_resource_group.virtual_network_extended[0].id
  type      = "Microsoft.Network/virtualNetworks@2024-07-01"
  response_export_values = [
    "extendedLocation.name"
  ]
}

locals {
  virtualMachines = [
    for virtualMachine in var.virtualMachines : merge(virtualMachine, {
      location = var.virtualNetworkExtended.enable && virtualMachine.network.locationExtended.enable ? data.azurerm_virtual_network.studio_extended[0].location : data.azurerm_virtual_network.studio.location
      edgeZone = var.virtualNetworkExtended.enable && virtualMachine.network.locationExtended.enable ? data.azapi_resource.virtual_network_extended[0].output.extendedLocation.name : null
      network = merge(virtualMachine.network, {
        subnetId = var.virtualNetworkExtended.enable && virtualMachine.network.locationExtended.enable ? "${data.azurerm_virtual_network.studio_extended[0].id}/subnets/${var.virtualNetworkExtended.subnetName}" : "${data.azurerm_virtual_network.studio.id}/subnets/${var.virtualNetwork.subnetName}"
      })
      adminLogin = merge(virtualMachine.adminLogin, {
        userName     = virtualMachine.adminLogin.userName != "" ? virtualMachine.adminLogin.userName : data.azurerm_key_vault_secret.admin_username.value
        userPassword = virtualMachine.adminLogin.userPassword != "" ? virtualMachine.adminLogin.userPassword : data.azurerm_key_vault_secret.admin_password.value
        sshKeyPublic = virtualMachine.adminLogin.sshKeyPublic != "" ? virtualMachine.adminLogin.sshKeyPublic : data.azurerm_key_vault_secret.ssh_key_public.value
      })
    })
  ]
  activeDirectory = merge(var.activeDirectory, {
    machine = merge(var.activeDirectory.machine, {
      adminLogin = merge(var.activeDirectory.machine.adminLogin, {
        userName     = var.activeDirectory.machine.adminLogin.userName != "" ? var.activeDirectory.machine.adminLogin.userName : data.azurerm_key_vault_secret.admin_username.value
        userPassword = var.activeDirectory.machine.adminLogin.userPassword != "" ? var.activeDirectory.machine.adminLogin.userPassword : data.azurerm_key_vault_secret.admin_password.value
      })
    })
  })
}

resource azurerm_network_interface job_scheduler {
  for_each = {
    for virtualMachine in local.virtualMachines : virtualMachine.name => virtualMachine if virtualMachine.enable
  }
  name                = each.value.name
  resource_group_name = azurerm_resource_group.job_scheduler.name
  location            = each.value.location
  edge_zone           = each.value.edgeZone
  ip_configuration {
    name                          = "ipConfig"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = each.value.network.subnetId
  }
  accelerated_networking_enabled = each.value.network.acceleration.enable
}

resource azurerm_linux_virtual_machine job_scheduler {
  for_each = {
    for virtualMachine in local.virtualMachines : virtualMachine.name => virtualMachine if virtualMachine.enable && lower(virtualMachine.osDisk.type) == "linux"
  }
  name                            = each.value.name
  resource_group_name             = azurerm_resource_group.job_scheduler.name
  location                        = each.value.location
  edge_zone                       = each.value.edgeZone
  source_image_id                 = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${each.value.image.resourceGroupName}/providers/Microsoft.Compute/galleries/${each.value.image.galleryName}/images/${each.value.image.definitionName}/versions/${each.value.image.versionId}"
  size                            = each.value.size
  admin_username                  = each.value.adminLogin.userName
  admin_password                  = each.value.adminLogin.userPassword
  disable_password_authentication = each.value.adminLogin.passwordAuth.disable
  custom_data                     = base64encode(file("scale.sh"))
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  network_interface_ids = [
    "${azurerm_resource_group.job_scheduler.id}/providers/Microsoft.Network/networkInterfaces/${each.value.name}"
  ]
  os_disk {
    storage_account_type = each.value.osDisk.storageType
    caching              = each.value.osDisk.cachingMode
    disk_size_gb         = each.value.osDisk.sizeGB > 0 ? each.value.osDisk.sizeGB : null
  }
  dynamic admin_ssh_key {
    for_each = each.value.adminLogin.sshKeyPublic != "" ? [1] : []
    content {
      username   = each.value.adminLogin.userName
      public_key = each.value.adminLogin.sshKeyPublic
    }
  }
  depends_on = [
    azurerm_network_interface.job_scheduler
  ]
}

resource azurerm_virtual_machine_extension job_scheduler_initialize_linux {
  for_each = {
    for virtualMachine in local.virtualMachines : virtualMachine.name => virtualMachine if virtualMachine.enable && virtualMachine.extension.custom.enable && lower(virtualMachine.osDisk.type) == "linux"
  }
  name                       = each.value.extension.custom.name
  type                       = "CustomScript"
  publisher                  = "Microsoft.Azure.Extensions"
  type_handler_version       = data.azurerm_app_configuration_keys.studio.items[index(data.azurerm_app_configuration_keys.studio.items[*].key, data.terraform_remote_state.core.outputs.appConfig.key.scriptExtensionLinux)].value
  automatic_upgrade_enabled  = false
  auto_upgrade_minor_version = true
  virtual_machine_id         = "${azurerm_resource_group.job_scheduler.id}/providers/Microsoft.Compute/virtualMachines/${each.value.name}"
  protected_settings = jsonencode({
    script = base64encode(
      templatefile(each.value.extension.custom.fileName, each.value.extension.custom.parameters)
    )
  })
  depends_on = [
    azurerm_linux_virtual_machine.job_scheduler
  ]
}

resource azurerm_monitor_diagnostic_setting job_scheduler_monitor_linux {
  for_each = {
    for virtualMachine in local.virtualMachines : virtualMachine.name => virtualMachine if virtualMachine.enable && lower(virtualMachine.osDisk.type) == "linux" && virtualMachine.monitor.enable
  }
  name                           = each.value.name
  target_resource_id             = "${azurerm_resource_group.job_scheduler.id}/providers/Microsoft.Compute/virtualMachines/${each.value.name}"
  log_analytics_workspace_id     = data.terraform_remote_state.core.outputs.monitor.logAnalytics.id
  log_analytics_destination_type = "Dedicated"
  metric {
    category = each.value.monitor.metric.category
  }
  depends_on = [
    azurerm_linux_virtual_machine.job_scheduler
  ]
}

resource azurerm_windows_virtual_machine job_scheduler {
  for_each = {
    for virtualMachine in local.virtualMachines : virtualMachine.name => virtualMachine if virtualMachine.enable && lower(virtualMachine.osDisk.type) == "windows"
  }
  name                = each.value.name
  resource_group_name = azurerm_resource_group.job_scheduler.name
  location            = each.value.location
  edge_zone           = each.value.edgeZone
  source_image_id     = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${each.value.image.resourceGroupName}/providers/Microsoft.Compute/galleries/${each.value.image.galleryName}/images/${each.value.image.definitionName}/versions/${each.value.image.versionId}"
  size                = each.value.size
  admin_username      = each.value.adminLogin.userName
  admin_password      = each.value.adminLogin.userPassword
  custom_data         = base64encode(templatefile("scale.ps1", {}))
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  network_interface_ids = [
    "${azurerm_resource_group.job_scheduler.id}/providers/Microsoft.Network/networkInterfaces/${each.value.name}"
  ]
  os_disk {
    storage_account_type = each.value.osDisk.storageType
    caching              = each.value.osDisk.cachingMode
    disk_size_gb         = each.value.osDisk.sizeGB > 0 ? each.value.osDisk.sizeGB : null
  }
  depends_on = [
    azurerm_network_interface.job_scheduler
  ]
}

resource azurerm_virtual_machine_extension job_scheduler_initialize_windows {
  for_each = {
    for virtualMachine in local.virtualMachines : virtualMachine.name => virtualMachine if virtualMachine.enable && virtualMachine.extension.custom.enable && lower(virtualMachine.osDisk.type) == "windows"
  }
  name                       = each.value.extension.custom.name
  type                       = "CustomScriptExtension"
  publisher                  = "Microsoft.Compute"
  type_handler_version       = data.azurerm_app_configuration_keys.studio.items[index(data.azurerm_app_configuration_keys.studio.items[*].key, data.terraform_remote_state.core.outputs.appConfig.key.scriptExtensionWindows)].value
  automatic_upgrade_enabled  = false
  auto_upgrade_minor_version = true
  virtual_machine_id         = "${azurerm_resource_group.job_scheduler.id}/providers/Microsoft.Compute/virtualMachines/${each.value.name}"
  protected_settings = jsonencode({
    commandToExecute = "PowerShell -ExecutionPolicy Unrestricted -EncodedCommand ${textencodebase64(
      templatefile(each.value.extension.custom.fileName, merge(each.value.extension.custom.parameters, {
        activeDirectory = local.activeDirectory
      })), "UTF-16LE"
    )}"
  })
  depends_on = [
    azurerm_windows_virtual_machine.job_scheduler
  ]
}

resource azurerm_monitor_diagnostic_setting job_scheduler_monitor_windows {
  for_each = {
    for virtualMachine in local.virtualMachines : virtualMachine.name => virtualMachine if virtualMachine.enable && lower(virtualMachine.osDisk.type) == "windows" && virtualMachine.monitor.enable
  }
  name                           = each.value.name
  target_resource_id             = "${azurerm_resource_group.job_scheduler.id}/providers/Microsoft.Compute/virtualMachines/${each.value.name}"
  log_analytics_workspace_id     = data.terraform_remote_state.core.outputs.monitor.logAnalytics.id
  log_analytics_destination_type = "Dedicated"
  metric {
    category = each.value.monitor.metric.category
  }
  depends_on = [
    azurerm_windows_virtual_machine.job_scheduler
  ]
}
