################################################################################################
# API Management (https://learn.microsoft.com/azure/api-management/api-management-key-concepts #
################################################################################################

variable apiManagement {
  type = object({
    name = string
    tier = string
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
  name                 = var.apiManagement.name
  resource_group_name  = azurerm_resource_group.api.name
  location             = azurerm_resource_group.api.location
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
  name                = "privatelink.azure-api.net"
  resource_group_name = azurerm_resource_group.api.name
}

resource azurerm_private_dns_zone_virtual_network_link api_management {
  name                  = "api-management"
  resource_group_name   = azurerm_private_dns_zone.api_management.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.api_management.name
  virtual_network_id    = data.azurerm_virtual_network.studio_region.id
}

resource azurerm_private_endpoint api_management {
  name                = "${azurerm_api_management.studio.name}-${azurerm_private_dns_zone_virtual_network_link.api_management.name}"
  resource_group_name = azurerm_api_management.studio.resource_group_name
  location            = azurerm_api_management.studio.location
  subnet_id           = data.azurerm_subnet.farm.id
  private_service_connection {
    name                           = azurerm_api_management.studio.name
    private_connection_resource_id = azurerm_api_management.studio.id
    is_manual_connection           = false
    subresource_names = [
      "gateway"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.api_management.name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.api_management.id
    ]
  }
}
