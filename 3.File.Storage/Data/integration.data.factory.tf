##############################################################################
# Data Factory (https://learn.microsoft.com/azure/data-factory/introduction) #
##############################################################################

resource azurerm_data_factory studio {
  count                            = var.data.integration.enable ? 1 : 0
  name                             = var.data.integration.name
  resource_group_name              = azurerm_resource_group.data_integration[0].name
  location                         = azurerm_resource_group.data_integration[0].location
  customer_managed_key_id          = var.data.integration.encryption.enable ? data.azurerm_key_vault_key.data_encryption.versionless_id : null
  customer_managed_key_identity_id = var.data.integration.encryption.enable ? data.azurerm_user_assigned_identity.studio.id : null
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
}

resource azurerm_data_factory_credential_user_managed_identity studio {
  count           = var.data.integration.enable ? 1 : 0
  name            = var.data.integration.name
  data_factory_id = azurerm_data_factory.studio[0].id
  identity_id     = data.azurerm_user_assigned_identity.studio.id
}

resource azurerm_data_factory_linked_service_cosmosdb studio {
  count            = var.data.integration.enable ? 1 : 0
  name             = var.data.integration.name
  data_factory_id  = azurerm_data_factory.studio[0].id
  account_endpoint = azurerm_cosmosdb_account.studio["sql"].endpoint
  account_key      = azurerm_cosmosdb_account.studio["sql"].primary_key
  database         = var.noSQL.databases[0].name
}
