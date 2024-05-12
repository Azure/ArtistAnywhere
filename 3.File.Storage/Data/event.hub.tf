#############################################################################
# Event Hub (https://learn.microsoft.com/azure/event-hubs/event-hubs-about) #
#############################################################################

variable eventHub {
  type = object({
    enable = bool
    name   = string
    tier   = string
  })
}

resource azurerm_resource_group data_event_hub {
  count    = var.eventHub.enable ? 1 : 0
  name     = "${azurerm_resource_group.data.name}.EventHub"
  location = var.cosmosDB.geoLocations[0].regionName
}

resource azurerm_eventhub_namespace data {
  count                         = var.eventHub.enable ? 1 : 0
  name                          = var.eventHub.name
  resource_group_name           = azurerm_resource_group.data_event_hub[0].name
  location                      = azurerm_resource_group.data_event_hub[0].location
  sku                           = var.eventHub.tier
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
  count               = var.eventHub.enable ? 1 : 0
  name                = "privatelink.servicebus.windows.net"
  resource_group_name = azurerm_resource_group.data_event_hub[0].name
}

resource azurerm_private_dns_zone_virtual_network_link event_hub {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.key => virtualNetwork if var.eventHub.enable
  }
  name                  = "${lower(each.value.key)}-event-hub"
  resource_group_name   = azurerm_private_dns_zone.event_hub[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.event_hub[0].name
  virtual_network_id    = each.value.id
}

resource azurerm_private_endpoint event_hub {
  for_each = {
    for subnet in local.virtualNetworksSubnetCompute : subnet.key => subnet if var.eventHub.enable && subnet.virtualNetworkEdgeZone == ""
  }
  name                = "${lower(each.value.virtualNetworkKey)}-event-hub"
  resource_group_name = each.value.resourceGroupName
  location            = each.value.regionName
  subnet_id           = "${each.value.virtualNetworkId}/subnets/${each.value.name}"
  private_service_connection {
    name                           = azurerm_eventhub_namespace.data[0].name
    private_connection_resource_id = azurerm_eventhub_namespace.data[0].id
    is_manual_connection           = false
    subresource_names = [
      "namespace"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.event_hub[each.value.virtualNetworkKey].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.event_hub[0].id
    ]
  }
}
