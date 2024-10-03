#######################################################
# Storage (https://learn.microsoft.com/azure/storage) #
#######################################################

variable storage {
  type = object({
    account = object({
      type        = string
      redundancy  = string
      performance = string
    })
    encryption = object({
      infrastructure = object({
        enable = bool
      })
      service = object({
        customKey = object({
          enable = bool
        })
      })
    })
  })
}

resource azurerm_role_assignment studio_storage_blob_data_owner {
  role_definition_name = "Storage Blob Data Owner" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/storage#storage-blob-data-owner
  principal_id         = data.azurerm_client_config.studio.object_id
  scope                = azurerm_storage_account.studio.id
}

resource azurerm_role_assignment studio_storage_blob_data_contributor {
  role_definition_name = "Storage Blob Data Contributor" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/storage#storage-blob-data-contributor
  principal_id         = azurerm_user_assigned_identity.studio.principal_id
  scope                = azurerm_storage_account.studio.id
}

resource azurerm_storage_account_customer_managed_key studio {
  count              = var.storage.encryption.service.customKey.enable ? 1 : 0
  key_vault_id       = azurerm_key_vault.studio.id
  key_name           = module.global.keyVault.keyName.dataEncryption
  storage_account_id = azurerm_storage_account.studio.id
}

resource azurerm_storage_account studio {
  name                              = module.global.storage.accountName
  resource_group_name               = azurerm_resource_group.studio.name
  location                          = azurerm_resource_group.studio.location
  account_kind                      = var.storage.account.type
  account_replication_type          = var.storage.account.redundancy
  account_tier                      = var.storage.account.performance
  infrastructure_encryption_enabled = var.storage.encryption.infrastructure.enable
  local_user_enabled                = false
  shared_access_key_enabled         = false
  allow_nested_items_to_be_public   = false
  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.studio.id
    ]
  }
  network_rules {
    default_action = "Deny"
    ip_rules = [
      jsondecode(data.http.client_address.response_body).ip
    ]
    dynamic private_link_access {
      for_each = module.global.defender.storage.malwareScanning.enable ? [1] : []
      content {
        endpoint_tenant_id   = data.azurerm_client_config.studio.tenant_id
        endpoint_resource_id = "/subscriptions/${data.azurerm_client_config.studio.subscription_id}/providers/Microsoft.Security/datascanners/storageDataScanner"
      }
    }
  }
}

resource azurerm_storage_container studio {
  for_each = {
    for containerName in module.global.storage.containerName : containerName => containerName
  }
  name                 = each.value
  storage_account_name = azurerm_storage_account.studio.name
}

resource azurerm_security_center_storage_defender studio {
  storage_account_id                          = azurerm_storage_account.studio.id
  malware_scanning_on_upload_enabled          = module.global.defender.storage.malwareScanning.enable
  malware_scanning_on_upload_cap_gb_per_month = module.global.defender.storage.malwareScanning.maxPerMonthGB
  sensitive_data_discovery_enabled            = module.global.defender.storage.sensitiveDataDiscovery.enable
}
