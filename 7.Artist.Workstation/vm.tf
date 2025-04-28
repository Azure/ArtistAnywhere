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
      hibernation = object({
        enable = bool
      })
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
          remoteAgentKey = string
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
  virtualMachines = flatten([
    for virtualMachine in var.virtualMachines : [
      for i in range(virtualMachine.count) : merge(virtualMachine, {
        resourceLocation = {
          name = virtualMachine.network.locationExtended.enable && var.extendedZone.enable ? var.extendedZone.name : data.terraform_remote_state.core.outputs.defaultLocation
          extendedZone = {
            name     = virtualMachine.network.locationExtended.enable && var.extendedZone.enable ? var.extendedZone.name : null
            location = virtualMachine.network.locationExtended.enable && var.extendedZone.enable ? var.extendedZone.location : null
          }
        }
        name = "${virtualMachine.name}${i}"
        network = merge(virtualMachine.network, {
          subnetId = "${virtualMachine.network.locationExtended.enable ? data.azurerm_virtual_network.studio_extended[0].id : data.azurerm_virtual_network.studio.id}/subnets/${var.virtualNetwork.subnetName}"
        })
        adminLogin = merge(virtualMachine.adminLogin, {
          userName     = virtualMachine.adminLogin.userName != "" ? virtualMachine.adminLogin.userName : data.azurerm_key_vault_secret.admin_username.value
          userPassword = virtualMachine.adminLogin.userPassword != "" ? virtualMachine.adminLogin.userPassword : data.azurerm_key_vault_secret.admin_password.value
          sshKeyPublic = virtualMachine.adminLogin.sshKeyPublic != "" ? virtualMachine.adminLogin.sshKeyPublic : data.azurerm_key_vault_secret.ssh_key_public.value
        })
      })
    ]
  ])
  activeDirectory = merge(var.activeDirectory, {
    machine = merge(var.activeDirectory.machine, {
      adminLogin = merge(var.activeDirectory.machine.adminLogin, {
        userName     = var.activeDirectory.machine.adminLogin.userName != "" ? var.activeDirectory.machine.adminLogin.userName : data.azurerm_key_vault_secret.admin_username.value
        userPassword = var.activeDirectory.machine.adminLogin.userPassword != "" ? var.activeDirectory.machine.adminLogin.userPassword : data.azurerm_key_vault_secret.admin_password.value
      })
    })
  })
}

resource azurerm_network_interface workstation {
  for_each = {
    for virtualMachine in local.virtualMachines : virtualMachine.name => virtualMachine if virtualMachine.enable
  }
  name                = each.value.name
  resource_group_name = azurerm_resource_group.workstation.name
  location            = each.value.resourceLocation.name
  edge_zone           = each.value.resourceLocation.extendedZone.name
  ip_configuration {
    name                          = "ipConfig"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = each.value.network.subnetId
  }
  accelerated_networking_enabled = each.value.network.acceleration.enable
}

resource azurerm_linux_virtual_machine workstation {
  for_each = {
    for virtualMachine in local.virtualMachines : virtualMachine.name => virtualMachine if virtualMachine.enable && lower(virtualMachine.osDisk.type) == "linux"
  }
  name                            = each.value.name
  resource_group_name             = azurerm_resource_group.workstation.name
  location                        = each.value.resourceLocation.name
  edge_zone                       = each.value.resourceLocation.extendedZone.name
  size                            = each.value.size
  source_image_id                 = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${each.value.image.resourceGroupName}/providers/Microsoft.Compute/galleries/${each.value.image.galleryName}/images/${each.value.image.definitionName}/versions/${each.value.image.versionId}"
  admin_username                  = each.value.adminLogin.userName
  admin_password                  = each.value.adminLogin.userPassword
  disable_password_authentication = each.value.adminLogin.passwordAuth.disable
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  network_interface_ids = [
    "${azurerm_resource_group.workstation.id}/providers/Microsoft.Network/networkInterfaces/${each.value.name}"
  ]
  os_disk {
    storage_account_type = each.value.osDisk.storageType
    caching              = each.value.osDisk.cachingMode
    disk_size_gb         = each.value.osDisk.sizeGB > 0 ? each.value.osDisk.sizeGB : null
  }
  additional_capabilities {
    hibernation_enabled = each.value.osDisk.hibernation.enable
  }
  dynamic admin_ssh_key {
    for_each = each.value.adminLogin.sshKeyPublic != "" ? [1] : []
    content {
      username   = each.value.adminLogin.userName
      public_key = each.value.adminLogin.sshKeyPublic
    }
  }
  depends_on = [
    azurerm_network_interface.workstation
  ]
}

resource azurerm_virtual_machine_extension workstation_initialize_linux {
  for_each = {
    for virtualMachine in local.virtualMachines : virtualMachine.name => virtualMachine if virtualMachine.enable && virtualMachine.extension.custom.enable && lower(virtualMachine.osDisk.type) == "linux"
  }
  name                       = each.value.extension.custom.name
  type                       = "CustomScript"
  publisher                  = "Microsoft.Azure.Extensions"
  type_handler_version       = data.azurerm_app_configuration_keys.studio.items[index(data.azurerm_app_configuration_keys.studio.items[*].key, data.terraform_remote_state.core.outputs.appConfig.key.scriptExtensionLinux)].value
  automatic_upgrade_enabled  = false
  auto_upgrade_minor_version = true
  virtual_machine_id         = "${azurerm_resource_group.workstation.id}/providers/Microsoft.Compute/virtualMachines/${each.value.name}"
  protected_settings = jsonencode({
    script = base64encode(
      templatefile(each.value.extension.custom.fileName, merge(each.value.extension.custom.parameters, {
        fileSystem = module.core.fileSystem.linux
      }))
    )
  })
  depends_on = [
    azurerm_linux_virtual_machine.workstation
  ]
}

# resource azurerm_virtual_machine_extension workstation_monitor_linux {
#   for_each = {
#     for virtualMachine in local.virtualMachines : virtualMachine.name => virtualMachine if virtualMachine.enable && lower(virtualMachine.osDisk.type) == "linux" && virtualMachine.extension.monitor.enable
#   }
#   name                       = each.value.extension.monitor.name
#   type                       = "AzureMonitorLinuxAgent"
#   publisher                  = "Microsoft.Azure.Monitor"
#   type_handler_version       = data.azurerm_app_configuration_keys.studio.items[index(data.azurerm_app_configuration_keys.studio.items[*].key, data.terraform_remote_state.core.outputs.appConfig.key.monitorAgentLinux)].value
#   automatic_upgrade_enabled  = true
#   auto_upgrade_minor_version = true
#   virtual_machine_id         = "${azurerm_resource_group.workstation.id}/providers/Microsoft.Compute/virtualMachines/${each.value.name}"
#   settings = jsonencode({
#     authentication = {
#       managedIdentity = {
#         identifier-name  = "mi_res_id"
#         identifier-value = data.azurerm_user_assigned_identity.studio.id
#       }
#     }
#   })
#   depends_on = [
#     azurerm_virtual_machine_extension.workstation_initialize_linux
#   ]
# }

# resource azurerm_monitor_data_collection_rule_association workstation_linux {
#   for_each = {
#     for virtualMachine in local.virtualMachines : virtualMachine.name => virtualMachine if virtualMachine.enable && lower(virtualMachine.osDisk.type) == "linux" && virtualMachine.extension.monitor.enable
#   }
#   target_resource_id          = azurerm_linux_virtual_machine.workstation[each.value.name].id
#   data_collection_endpoint_id = data.terraform_remote_state.core.outputs.monitor.dataCollection.endpoint.id
# }

resource azurerm_windows_virtual_machine workstation {
  for_each = {
    for virtualMachine in local.virtualMachines : virtualMachine.name => virtualMachine if virtualMachine.enable && lower(virtualMachine.osDisk.type) == "windows"
  }
  name                = each.value.name
  resource_group_name = azurerm_resource_group.workstation.name
  location            = each.value.resourceLocation.name
  edge_zone           = each.value.resourceLocation.extendedZone.name
  size                = each.value.size
  source_image_id     = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${each.value.image.resourceGroupName}/providers/Microsoft.Compute/galleries/${each.value.image.galleryName}/images/${each.value.image.definitionName}/versions/${each.value.image.versionId}"
  admin_username      = each.value.adminLogin.userName
  admin_password      = each.value.adminLogin.userPassword
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  network_interface_ids = [
    "${azurerm_resource_group.workstation.id}/providers/Microsoft.Network/networkInterfaces/${each.value.name}"
  ]
  os_disk {
    storage_account_type = each.value.osDisk.storageType
    caching              = each.value.osDisk.cachingMode
    disk_size_gb         = each.value.osDisk.sizeGB > 0 ? each.value.osDisk.sizeGB : null
  }
  additional_capabilities {
    hibernation_enabled = each.value.osDisk.hibernation.enable
  }
  depends_on = [
    azurerm_network_interface.workstation
  ]
}

resource azurerm_virtual_machine_extension workstation_initialize_windows {
  for_each = {
    for virtualMachine in local.virtualMachines : virtualMachine.name => virtualMachine if virtualMachine.enable && virtualMachine.extension.custom.enable && lower(virtualMachine.osDisk.type) == "windows"
  }
  name                       = each.value.extension.custom.name
  type                       = "CustomScriptExtension"
  publisher                  = "Microsoft.Compute"
  type_handler_version       = data.azurerm_app_configuration_keys.studio.items[index(data.azurerm_app_configuration_keys.studio.items[*].key, data.terraform_remote_state.core.outputs.appConfig.key.scriptExtensionWindows)].value
  automatic_upgrade_enabled  = false
  auto_upgrade_minor_version = true
  virtual_machine_id         = "${azurerm_resource_group.workstation.id}/providers/Microsoft.Compute/virtualMachines/${each.value.name}"
  protected_settings = jsonencode({
    commandToExecute = "PowerShell -ExecutionPolicy Unrestricted -EncodedCommand ${textencodebase64(
      templatefile(each.value.extension.custom.fileName, merge(each.value.extension.custom.parameters, {
        activeDirectory = local.activeDirectory
        fileSystem      = module.core.fileSystem.windows
      })), "UTF-16LE"
    )}"
  })
  depends_on = [
    azurerm_windows_virtual_machine.workstation
  ]
}

# resource azurerm_virtual_machine_extension workstation_monitor_windows {
#   for_each = {
#     for virtualMachine in local.virtualMachines : virtualMachine.name => virtualMachine if virtualMachine.enable && lower(virtualMachine.osDisk.type) == "windows" && virtualMachine.extension.monitor.enable
#   }
#   name                       = each.value.extension.monitor.name
#   type                       = "AzureMonitorWindowsAgent"
#   publisher                  = "Microsoft.Azure.Monitor"
#   type_handler_version       = data.azurerm_app_configuration_keys.studio.items[index(data.azurerm_app_configuration_keys.studio.items[*].key, data.terraform_remote_state.core.outputs.appConfig.key.monitorAgentWindows)].value
#   automatic_upgrade_enabled  = true
#   auto_upgrade_minor_version = true
#   virtual_machine_id         = "${azurerm_resource_group.workstation.id}/providers/Microsoft.Compute/virtualMachines/${each.value.name}"
#   settings = jsonencode({
#     authentication = {
#       managedIdentity = {
#         identifier-name  = "mi_res_id"
#         identifier-value = data.azurerm_user_assigned_identity.studio.id
#       }
#     }
#   })
#   depends_on = [
#     azurerm_virtual_machine_extension.workstation_initialize_windows
#   ]
# }

# resource azurerm_monitor_data_collection_rule_association workstation_windows {
#   for_each = {
#     for virtualMachine in local.virtualMachines : virtualMachine.name => virtualMachine if virtualMachine.enable && lower(virtualMachine.osDisk.type) == "windows" && virtualMachine.extension.monitor.enable
#   }
#   target_resource_id          = azurerm_windows_virtual_machine.workstation[each.value.name].id
#   data_collection_endpoint_id = data.terraform_remote_state.core.outputs.monitor.dataCollection.endpoint.id
# }
