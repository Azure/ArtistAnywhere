######################################################################
# Event Grid (https://learn.microsoft.com/azure/event-grid/overview) #
######################################################################

resource azurerm_eventgrid_namespace studio {
  name                  = module.global.message.eventGrid.name
  resource_group_name   = azurerm_resource_group.studio_message.name
  location              = azurerm_resource_group.studio_message.location
  sku                   = module.global.message.eventGrid.type
  capacity              = module.global.message.eventGrid.capacity
  public_network_access = "Disabled"
  inbound_ip_rule {
    action = "Allow"
    ip_mask = jsondecode(data.http.client_address.response_body).ip
  }
}

resource azurerm_eventgrid_system_topic subscription {
  name                   = replace(data.azurerm_subscription.current.display_name, " ", "-")
  resource_group_name    = azurerm_resource_group.studio.name
  location               = "Global"
  source_arm_resource_id = data.azurerm_subscription.current.id
  topic_type             = "Microsoft.Resources.Subscriptions"
  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.studio.id
    ]
  }
}

resource azurerm_eventgrid_system_topic key_vault {
  name                   = azurerm_key_vault.studio.name
  resource_group_name    = azurerm_key_vault.studio.resource_group_name
  location               = azurerm_key_vault.studio.location
  source_arm_resource_id = azurerm_key_vault.studio.id
  topic_type             = "Microsoft.KeyVault.Vaults"
  identity {
    type = "UserAssigned"
    identity_ids = [
     azurerm_user_assigned_identity.studio.id
    ]
  }
}

#############################################################################
# Event Hub (https://learn.microsoft.com/azure/event-hubs/event-hubs-about) #
#############################################################################

resource azurerm_eventhub_namespace studio {
  name                          = module.global.message.eventHub.name
  resource_group_name           = azurerm_resource_group.studio_message.name
  location                      = azurerm_resource_group.studio_message.location
  sku                           = module.global.message.eventHub.type
  public_network_access_enabled = false
  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.studio.id
    ]
  }
  network_rulesets = [{
    default_action                 = "Deny"
    trusted_service_access_enabled = true
    public_network_access_enabled  = false
    virtual_network_rule           = null
    ip_rule = [{
      action  = "Allow"
      ip_mask = jsondecode(data.http.client_address.response_body).ip
    }]
  }]
}

output message {
  value = {
    resourceGroupName = azurerm_resource_group.studio_message.name
    regionName        = azurerm_resource_group.studio_message.location
    eventGrid = {
      namespace = {
        id   = azurerm_eventgrid_namespace.studio.id
        name = azurerm_eventgrid_namespace.studio.name
      }
    }
  }
}
