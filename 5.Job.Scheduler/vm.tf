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
      subnetName = string
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
  }))
}

locals {
  virtualMachines = [
    for virtualMachine in var.virtualMachines : merge(virtualMachine, {
      resourceLocation = {
        name = virtualMachine.network.locationExtended.enable && var.extendedZone.enable ? var.extendedZone.name : data.terraform_remote_state.core.outputs.defaultLocation
        extendedZone = {
          name     = virtualMachine.network.locationExtended.enable && var.extendedZone.enable ? var.extendedZone.name : null
          location = virtualMachine.network.locationExtended.enable && var.extendedZone.enable ? var.extendedZone.location : null
        }
      }
      network = merge(virtualMachine.network, {
        subnetId = "${virtualMachine.network.locationExtended.enable ? data.azurerm_virtual_network.studio_extended[0].id : data.azurerm_virtual_network.studio.id}/subnets/${var.virtualNetwork.enable ? var.virtualNetwork.subnetName : virtualMachine.network.subnetName}"
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
  location            = each.value.resourceLocation.name
  edge_zone           = each.value.resourceLocation.extendedZone.name
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
  location                        = each.value.resourceLocation.name
  edge_zone                       = each.value.resourceLocation.extendedZone.name
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

# resource azurerm_virtual_machine_extension job_scheduler_monitor_linux {
#   for_each = {
#     for virtualMachine in local.virtualMachines : virtualMachine.name => virtualMachine if virtualMachine.enable && lower(virtualMachine.osDisk.type) == "linux" && virtualMachine.extension.monitor.enable
#   }
#   name                       = each.value.extension.monitor.name
#   type                       = "AzureMonitorLinuxAgent"
#   publisher                  = "Microsoft.Azure.Monitor"
#   type_handler_version       = data.azurerm_app_configuration_keys.studio.items[index(data.azurerm_app_configuration_keys.studio.items[*].key, data.terraform_remote_state.core.outputs.appConfig.key.monitorAgentWindows)].value
#   automatic_upgrade_enabled  = true
#   auto_upgrade_minor_version = true
#   virtual_machine_id         = "${azurerm_resource_group.job_scheduler.id}/providers/Microsoft.Compute/virtualMachines/${each.value.name}"
#   settings = jsonencode({
#     authentication = {
#       managedIdentity = {
#         identifier-name  = "mi_res_id"
#         identifier-value = data.azurerm_user_assigned_identity.studio.id
#       }
#     }
#   })
#   depends_on = [
#     azurerm_virtual_machine_extension.job_scheduler_initialize_linux
#   ]
# }

# resource azurerm_monitor_data_collection_rule_association job_scheduler_linux {
#   for_each = {
#     for virtualMachine in local.virtualMachines : virtualMachine.name => virtualMachine if virtualMachine.enable && lower(virtualMachine.osDisk.type) == "linux" && virtualMachine.extension.monitor.enable
#   }
#   target_resource_id          = azurerm_linux_virtual_machine.job_scheduler[each.value.name].id
#   data_collection_endpoint_id = data.terraform_remote_state.core.outputs.monitor.dataCollection.endpoint.id
# }

resource azurerm_windows_virtual_machine job_scheduler {
  for_each = {
    for virtualMachine in local.virtualMachines : virtualMachine.name => virtualMachine if virtualMachine.enable && lower(virtualMachine.osDisk.type) == "windows"
  }
  name                = each.value.name
  resource_group_name = azurerm_resource_group.job_scheduler.name
  location            = each.value.resourceLocation.name
  edge_zone           = each.value.resourceLocation.extendedZone.name
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

# resource azurerm_virtual_machine_extension job_scheduler_monitor_windows {
#   for_each = {
#     for virtualMachine in local.virtualMachines : virtualMachine.name => virtualMachine if virtualMachine.enable && lower(virtualMachine.osDisk.type) == "windows" && virtualMachine.extension.monitor.enable
#   }
#   name                       = each.value.extension.monitor.name
#   type                       = "AzureMonitorWindowsAgent"
#   publisher                  = "Microsoft.Azure.Monitor"
#   type_handler_version       = data.azurerm_app_configuration_keys.studio.items[index(data.azurerm_app_configuration_keys.studio.items[*].key, data.terraform_remote_state.core.outputs.appConfig.key.monitorAgentWindows)].value
#   automatic_upgrade_enabled  = true
#   auto_upgrade_minor_version = true
#   virtual_machine_id         = "${azurerm_resource_group.job_scheduler.id}/providers/Microsoft.Compute/virtualMachines/${each.value.name}"
#   settings = jsonencode({
#     authentication = {
#       managedIdentity = {
#         identifier-name  = "mi_res_id"
#         identifier-value = data.azurerm_user_assigned_identity.studio.id
#       }
#     }
#   })
#   depends_on = [
#     azurerm_virtual_machine_extension.job_scheduler_initialize_windows
#   ]
# }

# resource azurerm_monitor_data_collection_rule_association job_scheduler_windows {
#   for_each = {
#     for virtualMachine in local.virtualMachines : virtualMachine.name => virtualMachine if virtualMachine.enable && lower(virtualMachine.osDisk.type) == "windows" && virtualMachine.extension.monitor.enable
#   }
#   target_resource_id          = azurerm_windows_virtual_machine.job_scheduler[each.value.name].id
#   data_collection_endpoint_id = data.terraform_remote_state.core.outputs.monitor.dataCollection.endpoint.id
# }
