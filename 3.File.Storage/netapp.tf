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
      # coolAccess = object({
      #   enable = bool
      #   period = number
      # })
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
        # capacityPoolCoolAccess = capacityPool.coolAccess
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

resource azurerm_netapp_pool studio {
  for_each = {
    for capacityPool in var.netAppFiles.capacityPools : capacityPool.name => capacityPool if var.netAppFiles.enable && capacityPool.enable
  }
  name                = each.value.name
  resource_group_name = azurerm_resource_group.netapp[0].name
  location            = azurerm_resource_group.netapp[0].location
  service_level       = each.value.type
  size_in_tb          = each.value.sizeTiB
  account_name        = var.netAppFiles.name
  depends_on = [
    azurerm_netapp_account.studio
  ]
}

resource azurerm_netapp_volume studio {
  for_each = {
    for volume in local.netAppVolumes : "${volume.capacityPoolName}-${volume.name}" => volume
  }
  name                          = each.value.name
  resource_group_name           = azurerm_resource_group.netapp[0].name
  location                      = azurerm_resource_group.netapp[0].location
  pool_name                     = each.value.capacityPoolName
  service_level                 = each.value.capacityPoolType
  volume_path                   = each.value.path
  storage_quota_in_gb           = each.value.sizeGiB
  network_features              = each.value.network.features
  protocols                     = each.value.network.protocols
  subnet_id                     = data.azurerm_subnet.storage_netapp[0].id
  encryption_key_source         = var.netAppFiles.encryption.enable ? "Microsoft.KeyVault" : null
  key_vault_private_endpoint_id = var.netAppFiles.encryption.enable ? data.terraform_remote_state.network.outputs.keyVault.privateEndpoint.id : null
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
    azurerm_netapp_pool.studio
  ]
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
