######################################################################
# Event Grid (https://learn.microsoft.com/azure/event-grid/overview) #
######################################################################

resource azurerm_eventgrid_system_topic studio_subscription {
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

resource azurerm_eventgrid_system_topic studio_key_vault {
  name                   = "${module.global.eventGrid.name}-key-vault"
  resource_group_name    = azurerm_key_vault.studio.resource_group_name
  location               = azurerm_key_vault.studio.location
  source_arm_resource_id = azurerm_key_vault.studio.id
  topic_type             = "Microsoft.KeyVault.vaults"
  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.studio.id
    ]
  }
}
