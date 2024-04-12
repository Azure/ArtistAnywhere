#############################################################################
# Event Hub (https://learn.microsoft.com/azure/event-hubs/event-hubs-about) #
#############################################################################

resource azurerm_eventhub_namespace studio {
  name                          = var.event.hub.name
  resource_group_name           = azurerm_resource_group.event.name
  location                      = azurerm_resource_group.event.location
  sku                           = var.event.hub.tier
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
  name                = "privatelink.servicebus.windows.net"
  resource_group_name = azurerm_resource_group.event.name
}

resource azurerm_private_dns_zone_virtual_network_link event_hub {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.name => virtualNetwork
  }
  name                  = "${lower(each.value.name)}-event-hub"
  resource_group_name   = azurerm_private_dns_zone.event_hub.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.event_hub.name
  virtual_network_id    = each.value.id
}

resource azurerm_private_endpoint event_hub {
  for_each = {
    for subnet in local.virtualNetworksSubnetCompute : subnet.key => subnet
  }
  name                = "${lower(each.value.virtualNetworkName)}-event-hub"
  resource_group_name = each.value.resourceGroupName
  location            = each.value.regionName
  subnet_id           = "${each.value.virtualNetworkId}/subnets/${each.value.name}"
  private_service_connection {
    name                           = azurerm_eventhub_namespace.studio.name
    private_connection_resource_id = azurerm_eventhub_namespace.studio.id
    is_manual_connection           = false
    subresource_names = [
      "namespace"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.event_hub[each.value.virtualNetworkName].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.event_hub.id
    ]
  }
}
