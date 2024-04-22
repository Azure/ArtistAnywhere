##########################################################################################################################
# Network Address Translation (NAT) Gateway (https://learn.microsoft.com/azure/virtual-network/nat-gateway/nat-overview) #
##########################################################################################################################

variable natGateway {
  type = object({
    enable = bool
  })
}

locals {
  natGatewayNetworks = !var.natGateway.enable ? [] : [
    for virtualNetwork in local.virtualNetworks : virtualNetwork if virtualNetwork.edgeZone == ""
  ]
  natGatewayNetworksSubnets = flatten([
    for virtualNetwork in local.natGatewayNetworks : [
      for subnet in virtualNetwork.subnets : merge(subnet, {
        key                = "${virtualNetwork.name}-${subnet.name}"
        regionName         = virtualNetwork.regionName
        resourceGroupName  = virtualNetwork.resourceGroupName
        virtualNetworkId   = virtualNetwork.id
        virtualNetworkName = virtualNetwork.name
      }) if virtualNetwork.edgeZone == "" && subnet.name != "GatewaySubnet"
    ]
  ])
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

######################################################################################################################
# Public IP Address Prefix (https://learn.microsoft.com/azure/virtual-network/ip-services/public-ip-address-prefix ) #
######################################################################################################################

resource azurerm_public_ip_prefix nat_gateway {
  for_each = {
    for virtualNetwork in local.natGatewayNetworks : virtualNetwork.name => virtualNetwork
  }
  name                = "Gateway-NAT"
  resource_group_name = each.value.resourceGroupName
  location            = each.value.regionName
  prefix_length       = 31
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
