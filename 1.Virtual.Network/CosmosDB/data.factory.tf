##############################################################################
# Data Factory (https://learn.microsoft.com/azure/data-factory/introduction) #
##############################################################################

resource azurerm_data_factory studio {
  count                            = var.cosmosDB.dataFactory.enable ? 1 : 0
  name                             = var.cosmosDB.dataFactory.name
  resource_group_name              = azurerm_resource_group.database.name
  location                         = azurerm_resource_group.database.location
  customer_managed_key_id          = var.cosmosDB.doubleEncryption.enable ? data.azurerm_key_vault_key.data_encryption[0].versionless_id : null
  customer_managed_key_identity_id = var.cosmosDB.doubleEncryption.enable ? data.azurerm_user_assigned_identity.studio.id : null
  managed_virtual_network_enabled  = true
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
}

resource azurerm_data_factory_credential_user_managed_identity studio {
  count           = var.cosmosDB.dataFactory.enable ? 1 : 0
  name            = var.cosmosDB.dataFactory.name
  data_factory_id = azurerm_data_factory.studio[0].id
  identity_id     = data.azurerm_user_assigned_identity.studio.id
}

resource azurerm_data_factory_linked_service_cosmosdb studio {
  count           = var.cosmosDB.dataFactory.enable ? 1 : 0
  name            = var.cosmosDB.dataFactory.name
  data_factory_id = azurerm_data_factory.studio[0].id
}
