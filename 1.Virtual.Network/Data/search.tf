#################################################################################
# Search - https://learn.microsoft.com/azure/search/search-what-is-azure-search #
#################################################################################

variable search {
  type = object({
    name = string
    tier = string
    accessKeys = object({
      enable = bool
    })
  })
}

resource azurerm_private_dns_zone search {
  count               = var.noSQL.enable ? 1 : 0
  name                = "privatelink.search.windows.net"
  resource_group_name = azurerm_resource_group.data.name
}

resource azurerm_private_dns_zone_virtual_network_link search {
  count                 = var.noSQL.enable ? 1 : 0
  name                  = "search"
  resource_group_name   = azurerm_private_dns_zone.search[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.search[0].name
  virtual_network_id    = data.azurerm_virtual_network.studio.id
}

resource azurerm_private_endpoint search {
  count               = var.noSQL.enable ? 1 : 0
  name                = "${azurerm_search_service.cosmos_db[0].name}-search"
  resource_group_name = azurerm_resource_group.data.name
  location            = azurerm_resource_group.data.location
  subnet_id           = data.azurerm_subnet.data.id
  private_service_connection {
    name                           = azurerm_search_service.cosmos_db[0].name
    private_connection_resource_id = azurerm_search_service.cosmos_db[0].id
    is_manual_connection           = false
    subresource_names = [
      "searchService"
    ]
  }
  private_dns_zone_group {
    name = azurerm_search_service.cosmos_db[0].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.search[0].id
    ]
  }
}

resource azurerm_search_service cosmos_db {
  count                         = var.noSQL.enable ? 1 : 0
  name                          = var.search.name
  resource_group_name           = azurerm_resource_group.data.name
  location                      = azurerm_resource_group.data.location
  sku                           = var.search.tier
  local_authentication_enabled  = var.search.accessKeys.enable
  public_network_access_enabled = false
  identity {
    type = "SystemAssigned"
  }
}
