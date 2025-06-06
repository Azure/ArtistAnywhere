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

locals {
  storage = {
    account = {
      name = regex("storage_account_name${local.backendConfig.patternSuffix}", file("./Config/backend"))[0]
    }
    containerName = {
      terraformState = regex("container_name${local.backendConfig.patternSuffix}", file("./Config/backend"))[0]
    }
  }
}

resource azurerm_role_assignment storage_blob_data_owner {
  role_definition_name = "Storage Blob Data Owner" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/storage#storage-blob-data-owner
  principal_id         = data.azurerm_client_config.current.object_id
  scope                = azurerm_storage_account.main.id
}

resource azurerm_role_assignment storage_blob_data_contributor {
  role_definition_name = "Storage Blob Data Contributor" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/storage#storage-blob-data-contributor
  principal_id         = azurerm_user_assigned_identity.main.principal_id
  scope                = azurerm_storage_account.main.id
}

resource azurerm_storage_account_customer_managed_key main {
  count              = var.storage.encryption.service.customKey.enable ? 1 : 0
  key_vault_id       = azurerm_key_vault.main.id
  key_name           = local.keyVault.keyName.dataEncryption
  storage_account_id = azurerm_storage_account.main.id
}

resource azurerm_storage_account main {
  name                              = local.storage.account.name
  resource_group_name               = azurerm_resource_group.foundation.name
  location                          = azurerm_resource_group.foundation.location
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
      azurerm_user_assigned_identity.main.id
    ]
  }
  network_rules {
    default_action = "Deny"
    ip_rules = [
      jsondecode(data.http.client_address.response_body).ip
    ]
    private_link_access {
      endpoint_tenant_id   = data.azurerm_client_config.current.tenant_id
      endpoint_resource_id = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/providers/Microsoft.Security/dataScanners/storageDataScanner"
    }
  }
}

resource azurerm_storage_container main {
  for_each = {
    for containerName in local.storage.containerName : containerName => containerName
  }
  name               = each.value
  storage_account_id = azurerm_storage_account.main.id
}

output storage {
  value = merge(local.storage, {
    blob = {
      apiVersion   = "2025-05-05"
      endpointUrl  = "https://hpcai.blob.core.windows.net/bin"
      authTokenUrl = "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2021-02-01&resource=https%3A%2F%2Fstorage.azure.com%2F"
    }
  })
}
