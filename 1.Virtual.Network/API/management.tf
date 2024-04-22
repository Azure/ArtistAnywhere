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
  })
}

data external account_user {
  program = ["az", "account", "show", "--query", "user"]
}

resource azurerm_api_management studio {
  name                 = var.apiManagement.name
  resource_group_name  = azurerm_resource_group.api.name
  location             = azurerm_resource_group.api.location
  sku_name             = var.apiManagement.tier
  publisher_name       = var.apiManagement.publisher.name == "" ? data.azurerm_subscription.studio.display_name : var.apiManagement.publisher.name
  publisher_email      = var.apiManagement.publisher.email == "" ? data.external.account_user.result.name : var.apiManagement.publisher.email
  # virtual_network_type = "Internal"
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  # virtual_network_configuration {
  #   subnet_id = data.azurerm_subnet.farm.id
  # }
}

resource azurerm_private_dns_zone api_management {
  name                = "privatelink.azure-api.net"
  resource_group_name = azurerm_resource_group.api.name
}

resource azurerm_private_dns_zone_virtual_network_link api_management {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.name => virtualNetwork
  }
  name                  = "${lower(each.value.name)}-api-management"
  resource_group_name   = azurerm_private_dns_zone.api_management.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.api_management.name
  virtual_network_id    = each.value.id
}

resource azurerm_private_endpoint api_management {
  for_each = {
    for subnet in local.virtualNetworksSubnetCompute : subnet.key => subnet
  }
  name                = "${lower(each.value.virtualNetworkName)}-api-management"
  resource_group_name = each.value.resourceGroupName
  location            = each.value.regionName
  subnet_id           = "${each.value.virtualNetworkId}/subnets/${each.value.name}"
  private_service_connection {
    name                           = azurerm_api_management.studio.name
    private_connection_resource_id = azurerm_api_management.studio.id
    is_manual_connection           = false
    subresource_names = [
      "gateway"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.api_management[each.value.virtualNetworkName].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.api_management.id
    ]
  }
}
