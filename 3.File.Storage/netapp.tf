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
        enable      = bool
        name        = string
        mountPath   = string
        sizeGiB     = number
        permissions = number
        network = object({
          features  = string
          protocols = list(string)
        })
        exportPolicies = list(object({
          ruleIndex        = number
          ownerMode        = string
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
}

resource azurerm_resource_group netapp {
  count    = var.netAppFiles.enable ? 1 : 0
  name     = "${var.resourceGroupName}.NetAppFiles"
  location = local.regionName
  tags = {
    AAA = basename(path.cwd)
  }
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

# resource azurerm_netapp_pool storage {
#   for_each = {
#     for capacityPool in var.netAppFiles.capacityPools : capacityPool.name => capacityPool if var.netAppFiles.enable && capacityPool.enable
#   }
#   name                = each.value.name
#   resource_group_name = azurerm_resource_group.netapp[0].name
#   location            = azurerm_resource_group.netapp[0].location
#   service_level       = each.value.tier
#   size_in_tb          = each.value.sizeTiB
#   account_name        = var.netAppFiles.name
#   depends_on = [
#     azurerm_netapp_account.storage
#   ]
# }

# resource azurerm_netapp_volume storage {
#   for_each = {
#     for volume in local.netAppVolumes : "${volume.capacityPoolName}-${volume.name}" => volume
#   }
#   name                          = each.value.name
#   resource_group_name           = azurerm_resource_group.netapp[0].name
#   location                      = azurerm_resource_group.netapp[0].location
#   pool_name                     = each.value.capacityPoolName
#   service_level                 = each.value.capacityPoolTier
#   storage_quota_in_gb           = each.value.sizeGiB
#   volume_path                   = each.value.mountPath
#   network_features              = each.value.network.features
#   protocols                     = each.value.network.protocols
#   subnet_id                     = data.azurerm_subnet.storage_netapp[0].id
#   encryption_key_source         = var.netAppFiles.encryption.enable ? "Microsoft.KeyVault" : null
#   key_vault_private_endpoint_id = var.netAppFiles.encryption.enable ? data.terraform_remote_state.network.outputs.keyVaultPrivateEndpointId : null
#   account_name                  = var.netAppFiles.name
#   dynamic export_policy_rule {
#     for_each = each.value.exportPolicies
#     content {
#       rule_index          = export_policy_rule.value["ruleIndex"]
#       unix_read_only      = export_policy_rule.value["readOnly"]
#       unix_read_write     = export_policy_rule.value["readWrite"]
#       root_access_enabled = export_policy_rule.value["rootAccess"]
#       protocols_enabled   = export_policy_rule.value["networkProtocols"]
#       allowed_clients     = export_policy_rule.value["allowedClients"]
#     }
#   }
#   depends_on = [
#     azurerm_netapp_pool.storage
#   ]
# }

resource azapi_resource capacity_pool {
  for_each = {
    for capacityPool in var.netAppFiles.capacityPools : capacityPool.name => capacityPool if var.netAppFiles.enable && capacityPool.enable
  }
  name      = each.value.name
  type      = "Microsoft.NetApp/netAppAccounts/capacityPools@2024-07-01"
  parent_id = azurerm_netapp_account.storage[0].id
  location  = azurerm_netapp_account.storage[0].location
  body = jsonencode({
    properties = {
      serviceLevel = each.value.tier
      size         = each.value.sizeTiB * 1099511627776
    }
  })
  schema_validation_enabled = false
}

resource azapi_resource volume {
  for_each = {
    for volume in local.netAppVolumes : "${volume.capacityPoolName}-${volume.name}" => volume
  }
  name      = each.value.name
  type      = "Microsoft.NetApp/netAppAccounts/capacityPools/volumes@2024-07-01"
  parent_id = azapi_resource.capacity_pool[each.value.capacityPoolName].id
  location  = azapi_resource.capacity_pool[each.value.capacityPoolName].location
  body = jsonencode({
    properties = {
      subnetId        = data.azurerm_subnet.storage_netapp[0].id
      serviceLevel    = each.value.capacityPoolTier
      usageThreshold  = each.value.sizeGiB * 1073741824
      protocolTypes   = each.value.network.protocols
      networkFeatures = each.value.network.features
      unixPermissions = tostring(each.value.permissions)
      creationToken   = each.value.mountPath
      exportPolicy = {
        rules = [
          {
            ruleIndex      = each.value.exportPolicies[0].ruleIndex
            chownMode      = each.value.exportPolicies[0].ownerMode
            nfsv3          = each.value.exportPolicies[0].networkProtocols[0] == "NFSv3"
            nfsv41         = each.value.exportPolicies[0].networkProtocols[0] == "NFSv4.1"
            unixReadOnly   = each.value.exportPolicies[0].readOnly
            unixReadWrite  = each.value.exportPolicies[0].readWrite
            hasRootAccess  = each.value.exportPolicies[0].rootAccess
            allowedClients = each.value.exportPolicies[0].allowedClients[0]
            kerberos5ReadOnly   = false
            kerberos5ReadWrite  = false
            kerberos5iReadOnly  = false
            kerberos5iReadWrite = false
            kerberos5pReadOnly  = false
            kerberos5pReadWrite = false
          }
        ]
      }
    }
  })
  response_export_values = [
    "properties.mountTargets"
  ]
  schema_validation_enabled = false
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
  records             = jsondecode(azapi_resource.volume[each.key].output).properties.mountTargets[*].ipAddress
  ttl                 = var.netAppFiles.dnsRecord.ttlSeconds
}
