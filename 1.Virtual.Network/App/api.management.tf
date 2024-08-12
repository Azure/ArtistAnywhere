#################################################################################################
# API Management (https://learn.microsoft.com/azure/api-management/api-management-key-concepts) #
#################################################################################################

variable apiManagement {
  type = object({
    enable = bool
    name   = string
    tier   = string
    publisher = object({
      name  = string
      email = string
    })
    externalAccess = object({
      enable = bool
    })
  })
}

resource azurerm_api_management studio {
  count                = var.apiManagement.enable ? 1 : 0
  name                 = var.apiManagement.name
  resource_group_name  = azurerm_resource_group.app.name
  location             = azurerm_resource_group.app.location
  sku_name             = var.apiManagement.tier
  publisher_name       = var.apiManagement.publisher.name
  publisher_email      = var.apiManagement.publisher.email
  virtual_network_type = var.apiManagement.externalAccess.enable ? "External" : "Internal"
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  virtual_network_configuration {
    subnet_id = data.azurerm_subnet.farm.id
  }
}

resource azurerm_private_dns_zone api_management {
  count               = var.apiManagement.enable ? 1 : 0
  name                = "privatelink.azure-api.net"
  resource_group_name = azurerm_resource_group.app.name
}

resource azurerm_private_dns_zone_virtual_network_link api_management {
  count                 = var.apiManagement.enable ? 1 : 0
  name                  = "api-management"
  resource_group_name   = azurerm_private_dns_zone.api_management[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.api_management[0].name
  virtual_network_id    = data.azurerm_virtual_network.studio_region.id
}

resource azurerm_private_endpoint api_management {
  count               = var.apiManagement.enable ? 1 : 0
  name                = "${azurerm_api_management.studio[0].name}-${azurerm_private_dns_zone_virtual_network_link.api_management[0].name}"
  resource_group_name = azurerm_api_management.studio[0].resource_group_name
  location            = azurerm_api_management.studio[0].location
  subnet_id           = data.azurerm_subnet.farm.id
  private_service_connection {
    name                           = azurerm_api_management.studio[0].name
    private_connection_resource_id = azurerm_api_management.studio[0].id
    is_manual_connection           = false
    subresource_names = [
      "gateway"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.api_management[0].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.api_management[0].id
    ]
  }
}
