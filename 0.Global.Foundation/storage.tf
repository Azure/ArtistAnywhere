#######################################################
# Storage (https://learn.microsoft.com/azure/storage) #
#######################################################

variable storage {
  type = object({
    accountType        = string
    accountRedundancy  = string
    accountPerformance = string
  })
}

resource azurerm_storage_account studio {
  name                            = module.global.storage.accountName
  resource_group_name             = azurerm_resource_group.studio.name
  location                        = azurerm_resource_group.studio.location
  account_kind                    = var.storage.accountType
  account_replication_type        = var.storage.accountRedundancy
  account_tier                    = var.storage.accountPerformance
  allow_nested_items_to_be_public = false
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
  }
}

resource azurerm_storage_container studio {
  for_each             = module.global.storage.containerName
  name                 = each.value
  storage_account_name = azurerm_storage_account.studio.name
}
