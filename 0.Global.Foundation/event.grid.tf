######################################################################
# Event Grid (https://learn.microsoft.com/azure/event-grid/overview) #
######################################################################

resource azurerm_eventgrid_system_topic subscription {
  count                  = module.global.eventGrid.enable ? 1 : 0
  name                   = module.global.eventGrid.name
  resource_group_name    = azurerm_resource_group.studio.name
  location               = "Global"
  source_arm_resource_id = "/subscriptions/${data.azurerm_client_config.studio.subscription_id}"
  topic_type             = "Microsoft.Resources.Subscriptions"
  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.studio.id
    ]
  }
}

resource azurerm_eventgrid_system_topic storage {
  count                  = module.global.eventGrid.enable ? 1 : 0
  name                   = azurerm_storage_account.studio.name
  resource_group_name    = azurerm_storage_account.studio.resource_group_name
  location               = azurerm_storage_account.studio.location
  source_arm_resource_id = azurerm_storage_account.studio.id
  topic_type             = "Microsoft.Storage.StorageAccounts"
  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.studio.id
    ]
  }
}

resource azurerm_eventgrid_system_topic key_vault {
  count                  = module.global.eventGrid.enable && module.global.keyVault.enable ? 1 : 0
  name                   = azurerm_key_vault.studio[0].name
  resource_group_name    = azurerm_key_vault.studio[0].resource_group_name
  location               = azurerm_key_vault.studio[0].location
  source_arm_resource_id = azurerm_key_vault.studio[0].id
  topic_type             = "Microsoft.KeyVault.vaults"
  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.studio.id
    ]
  }
}
