################################################################################################
# API Management (https://learn.microsoft.com/azure/api-management/api-management-key-concepts #
################################################################################################

variable apiManagement {
  type = object({
    enable = bool
    name   = string
    tier   = string
    publisher = object({
      name  = string
      email = string
    })
  })
}

resource azurerm_api_management studio {
  count                = var.apiManagement.enable ? 1 : 0
  name                 = var.apiManagement.name
  resource_group_name  = module.global.resourceGroupName
  location             = module.global.resourceLocation.regionName
  sku_name             = var.apiManagement.tier
  publisher_name       = var.apiManagement.publisher.name
  publisher_email      = var.apiManagement.publisher.email
  virtual_network_type = "Internal"
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  virtual_network_configuration {
    subnet_id = local.virtualNetworksSubnetCompute[0].id
  }
  depends_on = [
    azurerm_subnet.studio
  ]
}

resource azurerm_private_dns_zone api_management {
  count               = var.apiManagement.enable ? 1 : 0
  name                = "privatelink.azure-api.net"
  resource_group_name = azurerm_resource_group.network.name
}

resource azurerm_private_dns_zone_virtual_network_link api_management {
  for_each = {
    for virtualNetwork in local.virtualNetworksExtended : virtualNetwork.key => virtualNetwork if var.apiManagement.enable
  }
  name                  = "${lower(each.value.key)}-api-management"
  resource_group_name   = azurerm_private_dns_zone.api_management[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.api_management[0].name
  virtual_network_id    = each.value.id
  depends_on = [
    azurerm_virtual_network.studio
  ]
}

resource azurerm_private_endpoint api_management {
  for_each = {
    for subnet in local.virtualNetworksSubnetCompute : subnet.key => subnet if var.apiManagement.enable && subnet.virtualNetworkEdgeZone == ""
  }
  name                = "${lower(each.value.virtualNetworkKey)}-api-management"
  resource_group_name = each.value.resourceGroupName
  location            = each.value.regionName
  subnet_id           = "${each.value.virtualNetworkId}/subnets/${each.value.name}"
  private_service_connection {
    name                           = azurerm_api_management.studio[0].name
    private_connection_resource_id = azurerm_api_management.studio[0].id
    is_manual_connection           = false
    subresource_names = [
      "gateway"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.api_management[each.value.virtualNetworkKey].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.api_management[0].id
    ]
  }
}
