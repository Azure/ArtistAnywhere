######################################################################
# Event Grid (https://learn.microsoft.com/azure/event-grid/overview) #
######################################################################

resource azurerm_eventgrid_system_topic studio {
  name                   = var.event.grid.name
  resource_group_name    = azurerm_resource_group.event.name
  location               = "Global"
  source_arm_resource_id = "/subscriptions/${data.azurerm_client_config.studio.subscription_id}"
  topic_type             = "Microsoft.Resources.Subscriptions"
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
}

resource azurerm_eventgrid_system_topic storage {
  name                   = data.azurerm_storage_account.studio.name
  resource_group_name    = data.azurerm_storage_account.studio.resource_group_name
  location               = data.azurerm_storage_account.studio.location
  source_arm_resource_id = data.azurerm_storage_account.studio.id
  topic_type             = "Microsoft.Storage.StorageAccounts"
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
}

resource azurerm_eventgrid_system_topic key_vault {
  count                  = module.global.keyVault.enable ? 1 : 0
  name                   = data.azurerm_key_vault.studio[0].name
  resource_group_name    = data.azurerm_key_vault.studio[0].resource_group_name
  location               = data.azurerm_key_vault.studio[0].location
  source_arm_resource_id = data.azurerm_key_vault.studio[0].id
  topic_type             = "Microsoft.KeyVault.vaults"
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
}

resource azurerm_private_dns_zone event_grid {
  name                = "privatelink.eventgrid.azure.net"
  resource_group_name = azurerm_resource_group.event.name
}

resource azurerm_private_dns_zone_virtual_network_link event_grid {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.key => virtualNetwork
  }
  name                  = "${lower(each.value.name)}-event-grid"
  resource_group_name   = azurerm_private_dns_zone.event_grid.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.event_grid.name
  virtual_network_id    = each.value.id
}
