#############################################################################
# Event Hub (https://learn.microsoft.com/azure/event-hubs/event-hubs-about) #
#############################################################################

resource azurerm_eventhub_namespace data {
  count                         = var.data.integration.enable ? 1 : 0
  name                          = var.data.integration.name
  resource_group_name           = azurerm_resource_group.data_integration[0].name
  location                      = azurerm_resource_group.data_integration[0].location
  sku                           = var.data.integration.tier
  public_network_access_enabled = true
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  network_rulesets = [{
    default_action                 = "Deny"
    public_network_access_enabled  = true
    trusted_service_access_enabled = true
    virtual_network_rule           = null
    ip_rule = [{
      action  = "Allow"
      ip_mask = jsondecode(data.http.client_address.response_body).ip
    }]
  }]
}

resource azurerm_private_dns_zone event_hub {
  count               = var.data.integration.enable ? 1 : 0
  name                = "privatelink.servicebus.windows.net"
  resource_group_name = azurerm_resource_group.data_integration[0].name
}

resource azurerm_private_dns_zone_virtual_network_link event_hub {
  count                 = var.data.integration.enable ? 1 : 0
  name                  = "event-hub"
  resource_group_name   = azurerm_private_dns_zone.event_hub[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.event_hub[0].name
  virtual_network_id    = data.azurerm_virtual_network.studio_region.id
}

resource azurerm_private_endpoint event_hub {
  count               = var.data.integration.enable ? 1 : 0
  name                = "${azurerm_eventhub_namespace.data[0].name}-${azurerm_private_dns_zone_virtual_network_link.event_hub[0].name}"
  resource_group_name = azurerm_eventhub_namespace.data[0].resource_group_name
  location            = azurerm_eventhub_namespace.data[0].location
  subnet_id           = data.azurerm_subnet.data.id
  private_service_connection {
    name                           = azurerm_eventhub_namespace.data[0].name
    private_connection_resource_id = azurerm_eventhub_namespace.data[0].id
    is_manual_connection           = false
    subresource_names = [
      "namespace"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.event_hub[0].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.event_hub[0].id
    ]
  }
}
