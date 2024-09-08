#######################################################################################################
# NetApp Files (https://learn.microsoft.com/azure/azure-netapp-files/azure-netapp-files-introduction) #
#######################################################################################################

variable netAppFiles {
  type = object({
    enable = bool
    name   = string
    dnsRecord = object({
      namePrefix = string
      ttlSeconds = number
    })
    capacityPools = list(object({
      enable  = bool
      name    = string
      tier    = string
      sizeTiB = number
      volumes = list(object({
        enable    = bool
        name      = string
        mountPath = string
        sizeGiB   = number
        network = object({
          features  = string
          protocols = list(string)
        })
        exportPolicies = list(object({
          ruleIndex        = number
          readOnly         = bool
          readWrite        = bool
          rootAccess       = bool
          networkProtocols = list(string)
          allowedClients   = list(string)
        }))
      }))
    }))
    encryption = object({
      enable = bool
    })
    loadFiles = object({
      enable = bool
      virtualMachine = object({
        size = string
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
          acceleration = object({
            enable = bool
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
        operatingSystem = object({
          type = string
          disk = object({
            storageType = string
            cachingType = string
            sizeGB      = number
          })
        })
        extension = object({
          custom = object({
            enable   = bool
            name     = string
            fileName = string
            parameters = object({
            })
          })
        })
      })
    })
  })
}

data azurerm_subnet storage_netapp {
  count                = var.netAppFiles.enable ? 1 : 0
  name                 = "StorageNetApp"
  resource_group_name  = data.azurerm_virtual_network.studio_region.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.studio_region.name
}

locals {
  netAppVolumes = flatten([
    for capacityPool in var.netAppFiles.capacityPools : [
      for volume in capacityPool.volumes : merge(volume, {
        capacityPoolName = capacityPool.name
        capacityPoolTier = capacityPool.tier
      }) if volume.enable
    ] if var.netAppFiles.enable && capacityPool.enable
  ])
  virtualMachine = merge(var.netAppFiles.loadFiles.virtualMachine, {
    image = merge(var.netAppFiles.loadFiles.virtualMachine.image, {
      plan = {
        publisher = try(data.terraform_remote_state.image.outputs.linuxPlan.publisher, var.netAppFiles.loadFiles.virtualMachine.image.plan.publisher)
        product   = try(data.terraform_remote_state.image.outputs.linuxPlan.offer, var.netAppFiles.loadFiles.virtualMachine.image.plan.product)
        name      = try(data.terraform_remote_state.image.outputs.linuxPlan.sku, var.netAppFiles.loadFiles.virtualMachine.image.plan.name)
      }
    })
    adminLogin = merge(var.netAppFiles.loadFiles.virtualMachine.adminLogin, {
      userName     = var.netAppFiles.loadFiles.virtualMachine.adminLogin.userName != "" ? var.netAppFiles.loadFiles.virtualMachine.adminLogin.userName : data.azurerm_key_vault_secret.admin_username.value
      userPassword = var.netAppFiles.loadFiles.virtualMachine.adminLogin.userPassword != "" ? var.netAppFiles.loadFiles.virtualMachine.adminLogin.userPassword : data.azurerm_key_vault_secret.admin_password.value
      sshKeyPublic = var.netAppFiles.loadFiles.virtualMachine.adminLogin.sshKeyPublic != "" ? var.netAppFiles.loadFiles.virtualMachine.adminLogin.sshKeyPublic : data.azurerm_key_vault_secret.ssh_key_public.value
    })
  })
  fileSystemLinux = one([
    for fileSystem in module.global.fileSystems : fileSystem.linux if fileSystem.enable
  ])
}

resource azurerm_resource_group netapp {
  count    = var.netAppFiles.enable ? 1 : 0
  name     = "${var.resourceGroupName}.NetApp"
  location = module.global.resourceLocation.regionName
}

resource azurerm_resource_group netapp_data {
  count    = var.netAppFiles.enable && var.netAppFiles.loadFiles.enable ? 1 : 0
  name     = "${azurerm_resource_group.netapp[0].name}.Data"
  location = module.global.resourceLocation.regionName
}

resource azurerm_netapp_account storage {
  count               = var.netAppFiles.enable ? 1 : 0
  name                = var.netAppFiles.name
  resource_group_name = azurerm_resource_group.netapp[0].name
  location            = azurerm_resource_group.netapp[0].location
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
}

resource azurerm_netapp_account_encryption storage {
  count                     = var.netAppFiles.enable && var.netAppFiles.encryption.enable ? 1 : 0
  netapp_account_id         = azurerm_netapp_account.storage[0].id
  user_assigned_identity_id = data.azurerm_user_assigned_identity.studio.id
  encryption_key            = data.azurerm_key_vault_key.data_encryption.versionless_id
}

resource azurerm_netapp_pool storage {
  for_each = {
    for capacityPool in var.netAppFiles.capacityPools : capacityPool.name => capacityPool if var.netAppFiles.enable && capacityPool.enable
  }
  name                = each.value.name
  resource_group_name = azurerm_resource_group.netapp[0].name
  location            = azurerm_resource_group.netapp[0].location
  service_level       = each.value.tier
  size_in_tb          = each.value.sizeTiB
  account_name        = var.netAppFiles.name
  depends_on = [
    azurerm_netapp_account.storage
  ]
}

resource azurerm_netapp_volume storage {
  for_each = {
    for volume in local.netAppVolumes : "${volume.capacityPoolName}-${volume.name}" => volume
  }
  name                          = each.value.name
  resource_group_name           = azurerm_resource_group.netapp[0].name
  location                      = azurerm_resource_group.netapp[0].location
  pool_name                     = each.value.capacityPoolName
  service_level                 = each.value.capacityPoolTier
  storage_quota_in_gb           = each.value.sizeGiB
  volume_path                   = each.value.mountPath
  network_features              = each.value.network.features
  protocols                     = each.value.network.protocols
  subnet_id                     = data.azurerm_subnet.storage_netapp[0].id
  encryption_key_source         = var.netAppFiles.encryption.enable ? "Microsoft.KeyVault" : null
  key_vault_private_endpoint_id = var.netAppFiles.encryption.enable ? data.terraform_remote_state.network.outputs.keyVaultPrivateEndpointId : null
  account_name                  = var.netAppFiles.name
  dynamic export_policy_rule {
    for_each = each.value.exportPolicies
    content {
      rule_index          = export_policy_rule.value["ruleIndex"]
      unix_read_only      = export_policy_rule.value["readOnly"]
      unix_read_write     = export_policy_rule.value["readWrite"]
      root_access_enabled = export_policy_rule.value["rootAccess"]
      protocols_enabled   = export_policy_rule.value["networkProtocols"]
      allowed_clients     = export_policy_rule.value["allowedClients"]
    }
  }
  depends_on = [
    azurerm_netapp_pool.storage
  ]
}

############################################################################
# Private DNS (https://learn.microsoft.com/azure/dns/private-dns-overview) #
############################################################################

resource azurerm_private_dns_a_record netapp {
  for_each = {
    for volume in local.netAppVolumes : "${volume.capacityPoolName}-${volume.name}" => volume
  }
  name                = "${var.netAppFiles.dnsRecord.namePrefix}-${lower(each.value.name)}"
  resource_group_name = data.azurerm_private_dns_zone.studio.resource_group_name
  zone_name           = data.azurerm_private_dns_zone.studio.name
  records             = azurerm_netapp_volume.storage[each.key].mount_ip_addresses
  ttl                 = var.netAppFiles.dnsRecord.ttlSeconds
  depends_on = [
    azurerm_netapp_volume.storage
  ]
}

#########################################################################
# Virtual Machines (https://learn.microsoft.com/azure/virtual-machines) #
#########################################################################

resource azurerm_network_interface netapp_data {
  count               = var.netAppFiles.enable && var.netAppFiles.loadFiles.enable ? 1 : 0
  name                = var.netAppFiles.name
  resource_group_name = azurerm_resource_group.netapp_data[0].name
  location            = azurerm_resource_group.netapp_data[0].location
  ip_configuration {
    name                          = "ipConfig"
    subnet_id                     = data.azurerm_subnet.storage_region.id
    private_ip_address_allocation = "Dynamic"
  }
  accelerated_networking_enabled = local.virtualMachine.network.acceleration.enable
  depends_on = [
    azurerm_netapp_volume.storage
  ]
}

 resource azurerm_linux_virtual_machine netapp_data {
  count                           = var.netAppFiles.enable && var.netAppFiles.loadFiles.enable ? 1 : 0
  name                            = var.netAppFiles.name
  resource_group_name             = azurerm_resource_group.netapp_data[0].name
  location                        = azurerm_resource_group.netapp_data[0].location
  size                            = local.virtualMachine.size
  source_image_id                 = "/subscriptions/${data.azurerm_client_config.studio.subscription_id}/resourceGroups/${local.virtualMachine.image.resourceGroupName}/providers/Microsoft.Compute/galleries/${local.virtualMachine.image.galleryName}/images/${local.virtualMachine.image.definitionName}/versions/${local.virtualMachine.image.versionId}"
  admin_username                  = local.virtualMachine.adminLogin.userName
  admin_password                  = local.virtualMachine.adminLogin.userPassword
  disable_password_authentication = local.virtualMachine.adminLogin.passwordAuth.disable
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  network_interface_ids = [
    azurerm_network_interface.netapp_data[0].id
  ]
  os_disk {
    storage_account_type = local.virtualMachine.operatingSystem.disk.storageType
    caching              = local.virtualMachine.operatingSystem.disk.cachingType
    disk_size_gb         = local.virtualMachine.operatingSystem.disk.sizeGB > 0 ? local.virtualMachine.operatingSystem.disk.sizeGB : null
  }
  dynamic plan {
    for_each = local.virtualMachine.image.plan.publisher != "" ? [1] : []
    content {
      publisher = local.virtualMachine.image.plan.publisher
      product   = local.virtualMachine.image.plan.product
      name      = local.virtualMachine.image.plan.name
    }
  }
  dynamic admin_ssh_key {
    for_each = local.virtualMachine.adminLogin.sshKeyPublic != "" ? [1] : []
    content {
      username   = local.virtualMachine.adminLogin.userName
      public_key = local.virtualMachine.adminLogin.sshKeyPublic
    }
  }
 }

resource azurerm_virtual_machine_extension netapp_data {
  count                      = var.netAppFiles.enable && var.netAppFiles.loadFiles.enable ? 1 : 0
  name                       = local.virtualMachine.extension.custom.name
  type                       = "CustomScript"
  publisher                  = "Microsoft.Azure.Extensions"
  type_handler_version       = "2.1"
  automatic_upgrade_enabled  = false
  auto_upgrade_minor_version = true
  virtual_machine_id         = azurerm_linux_virtual_machine.netapp_data[0].id
  protected_settings = jsonencode({
    script = base64encode(
      templatefile(local.virtualMachine.extension.custom.fileName, merge(local.virtualMachine.extension.custom.parameters, {
        fileSystem = local.fileSystemLinux
      }))
    )
  })
}
