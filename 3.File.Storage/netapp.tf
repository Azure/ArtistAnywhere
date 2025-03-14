#######################################################################################################
# NetApp Files (https://learn.microsoft.com/azure/azure-netapp-files/azure-netapp-files-introduction) #
#######################################################################################################

variable netAppFiles {
  type = object({
    enable = bool
    name   = string
    capacityPools = list(object({
      enable  = bool
      name    = string
      type    = string
      sizeTiB = number
      coolAccess = object({
        enable = bool
        period = number
      })
      volumes = list(object({
        enable      = bool
        name        = string
        path        = string
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
    backup = object({
      enable = bool
      name   = string
      policy = object({
        enable = bool
        name   = string
        retention = object({
          daily   = number
          weekly  = number
          monthly = number
        })
      })
    })
    encryption = object({
      enable = bool
    })
  })
}

data azurerm_subnet storage_netapp {
  count                = var.netAppFiles.enable ? 1 : 0
  name                 = "StorageNetApp"
  resource_group_name  = data.azurerm_virtual_network.studio.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.studio.name
}

locals {
  netAppVolumes = flatten([
    for capacityPool in var.netAppFiles.capacityPools : [
      for volume in capacityPool.volumes : merge(volume, {
        capacityPoolName       = capacityPool.name
        capacityPoolType       = capacityPool.type
        capacityPoolCoolAccess = capacityPool.coolAccess
      }) if volume.enable
    ] if var.netAppFiles.enable && capacityPool.enable
  ])
}

resource azurerm_resource_group netapp {
  count    = var.netAppFiles.enable ? 1 : 0
  name     = "${var.resourceGroupName}.NetApp"
  location = local.location
  tags = {
    AAA = basename(path.cwd)
  }
}

resource azurerm_netapp_account studio {
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
  dynamic active_directory {
    for_each = var.activeDirectory.enable ? [1] : []
    content {
      domain          = var.activeDirectory.domainName
      username        = local.activeDirectory.machine.adminLogin.userName
      password        = local.activeDirectory.machine.adminLogin.userPassword
      smb_server_name = var.activeDirectory.machine.name
      dns_servers = [
        var.activeDirectory.machine.ip
      ]
    }
  }
}

resource azurerm_netapp_account_encryption studio {
  count                     = var.netAppFiles.enable && var.netAppFiles.encryption.enable ? 1 : 0
  netapp_account_id         = azurerm_netapp_account.studio[0].id
  user_assigned_identity_id = data.azurerm_user_assigned_identity.studio.id
  encryption_key            = data.azurerm_key_vault_key.data_encryption.versionless_id
}

# resource azurerm_netapp_pool studio {
#   for_each = {
#     for capacityPool in var.netAppFiles.capacityPools : capacityPool.name => capacityPool if var.netAppFiles.enable && capacityPool.enable
#   }
#   name                = each.value.name
#   resource_group_name = azurerm_resource_group.netapp[0].name
#   location            = azurerm_resource_group.netapp[0].location
#   service_level       = each.value.type
#   size_in_tb          = each.value.sizeTiB
#   account_name        = var.netAppFiles.name
#   depends_on = [
#     azurerm_netapp_account.studio
#   ]
# }

# resource azurerm_netapp_volume studio {
#   for_each = {
#     for volume in local.netAppVolumes : "${volume.capacityPoolName}-${volume.name}" => volume
#   }
#   name                          = each.value.name
#   resource_group_name           = azurerm_resource_group.netapp[0].name
#   location                      = azurerm_resource_group.netapp[0].location
#   pool_name                     = each.value.capacityPoolName
#   service_level                 = each.value.capacityPoolType
#   volume_path                   = each.value.path
#   storage_quota_in_gb           = each.value.sizeGiB
#   network_features              = each.value.network.features
#   protocols                     = each.value.network.protocols
#   subnet_id                     = data.azurerm_subnet.storage_netapp[0].id
#   encryption_key_source         = var.netAppFiles.encryption.enable ? "Microsoft.KeyVault" : null
#   key_vault_private_endpoint_id = var.netAppFiles.encryption.enable ? data.terraform_remote_state.network.outputs.keyVault.privateEndpoint.id : null
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
#     azurerm_netapp_pool.studio
#   ]
# }

resource azapi_resource capacity_pool {
  for_each = {
    for capacityPool in var.netAppFiles.capacityPools : capacityPool.name => capacityPool if var.netAppFiles.enable && capacityPool.enable
  }
  name      = each.value.name
  type      = "Microsoft.NetApp/netAppAccounts/capacityPools@2024-09-01"
  parent_id = azurerm_netapp_account.studio[0].id
  location  = azurerm_netapp_account.studio[0].location
  body = {
    properties = {
      serviceLevel = each.value.type
      size         = each.value.sizeTiB * 1099511627776
      coolAccess   = each.value.coolAccess.enable
    }
  }
  schema_validation_enabled = false
}

resource azapi_resource volume {
  for_each = {
    for volume in local.netAppVolumes : "${volume.capacityPoolName}-${volume.name}" => volume
  }
  name      = each.value.name
  type      = "Microsoft.NetApp/netAppAccounts/capacityPools/volumes@2024-09-01"
  parent_id = azapi_resource.capacity_pool[each.value.capacityPoolName].id
  location  = azapi_resource.capacity_pool[each.value.capacityPoolName].location
  body = {
    properties = {
      subnetId        = data.azurerm_subnet.storage_netapp[0].id
      serviceLevel    = each.value.capacityPoolType
      usageThreshold  = each.value.sizeGiB * 1073741824
      protocolTypes   = each.value.network.protocols
      networkFeatures = each.value.network.features
      creationToken   = each.value.path
      coolAccess      = each.value.capacityPoolCoolAccess.enable
      coolnessPeriod  = each.value.capacityPoolCoolAccess.period
      unixPermissions = tostring(each.value.permissions)
      securityStyle   = "Unix"
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
  }
  response_export_values = [
    "properties.mountTargets"
  ]
  schema_validation_enabled = false
}

############################################################################
# Private DNS (https://learn.microsoft.com/azure/dns/private-dns-overview) #
############################################################################

resource azurerm_private_dns_a_record netapp {
  count               = var.netAppFiles.enable && length(azapi_resource.volume) > 0 ? 1 : 0
  name                = "${var.dnsRecord.name}-data"
  resource_group_name = data.azurerm_private_dns_zone.studio.resource_group_name
  zone_name           = data.azurerm_private_dns_zone.studio.name
  ttl                 = var.dnsRecord.ttlSeconds
  records = distinct([
    for volume in azapi_resource.volume : volume.output.properties.mountTargets[0].ipAddress
  ])
}

#################################################################################################
# NetApp Files Backup (https://learn.microsoft.com/azure/azure-netapp-files/backup-introduction #
#################################################################################################

resource azurerm_netapp_backup_vault studio {
  count               = var.netAppFiles.enable && var.netAppFiles.backup.enable ? 1 : 0
  name                = var.netAppFiles.backup.name
  resource_group_name = azurerm_netapp_account.studio[0].resource_group_name
  location            = azurerm_netapp_account.studio[0].location
  account_name        = azurerm_netapp_account.studio[0].name
}

resource azurerm_netapp_backup_policy studio {
  count                   = var.netAppFiles.enable && var.netAppFiles.backup.enable ? 1 : 0
  name                    = var.netAppFiles.backup.policy.name
  resource_group_name     = azurerm_netapp_account.studio[0].resource_group_name
  location                = azurerm_netapp_account.studio[0].location
  account_name            = azurerm_netapp_account.studio[0].name
  daily_backups_to_keep   = var.netAppFiles.backup.policy.retention.daily
  weekly_backups_to_keep  = var.netAppFiles.backup.policy.retention.weekly
  monthly_backups_to_keep = var.netAppFiles.backup.policy.retention.monthly
  enabled                 = var.netAppFiles.backup.policy.enable
}

######################################################################################################
# NetApp Files Snapshot (https://learn.microsoft.com/azure/azure-netapp-files/snapshots-introduction #
######################################################################################################
