##########################################################################################################################
# Network Address Translation (NAT) Gateway (https://learn.microsoft.com/azure/virtual-network/nat-gateway/nat-overview) #
##########################################################################################################################

variable natGateway {
  type = object({
    enable = bool
  })
}

locals {
  natGatewayNetworks = [
    for virtualNetwork in local.virtualNetworksRegional : virtualNetwork if var.natGateway.enable
  ]
  natGatewayNetworksSubnets = [
    for subnet in local.virtualNetworksSubnets : subnet if var.natGateway.enable && subnet.name != "GatewaySubnet" && subnet.virtualNetworkEdgeZone == ""
  ]
}

resource azurerm_nat_gateway studio {
  for_each = {
    for virtualNetwork in local.natGatewayNetworks : virtualNetwork.name => virtualNetwork
  }
  name                = "Gateway-NAT"
  resource_group_name = each.value.resourceGroupName
  location            = each.value.regionName
  depends_on = [
    azurerm_resource_group.network_regions
  ]
}

resource azurerm_nat_gateway_public_ip_prefix_association studio {
  for_each = {
    for virtualNetwork in local.natGatewayNetworks : virtualNetwork.name => virtualNetwork
  }
  nat_gateway_id      = azurerm_nat_gateway.studio[each.value.name].id
  public_ip_prefix_id = azurerm_public_ip_prefix.nat_gateway[each.value.name].id
}

resource azurerm_subnet_nat_gateway_association studio {
  for_each = {
    for subnet in local.natGatewayNetworksSubnets : subnet.key => subnet
  }
  nat_gateway_id = azurerm_nat_gateway.studio[each.value.virtualNetworkName].id
  subnet_id      = "${each.value.virtualNetworkId}/subnets/${each.value.name}"
  depends_on = [
    azurerm_subnet.studio
  ]
}
