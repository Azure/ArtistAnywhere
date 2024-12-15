##########################################################################################################################
# Network Address Translation (NAT) Gateway (https://learn.microsoft.com/azure/virtual-network/nat-gateway/nat-overview) #
##########################################################################################################################

variable natGateway {
  type = object({
    enable = bool
    ipAddress = object({
      type = string
      tier = string
    })
  })
}

locals {
  natGatewayNetworks = [
    for virtualNetwork in local.virtualNetworks : virtualNetwork if var.natGateway.enable && virtualNetwork.extendedZoneName == ""
  ]
  natGatewayNetworksSubnets = flatten([
    for virtualNetwork in local.natGatewayNetworks : [
      for subnet in virtualNetwork.subnets : merge(subnet, {
        key               = "${virtualNetwork.key}-${subnet.name}"
        virtualNetworkKey = virtualNetwork.key
        virtualNetworkId  = virtualNetwork.id
      }) if virtualNetwork.extendedZoneName == "" && subnet.name != "GatewaySubnet"
    ]
  ])
}

resource azurerm_nat_gateway studio {
  for_each = {
    for virtualNetwork in local.natGatewayNetworks : virtualNetwork.key => virtualNetwork
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
  nat_gateway_id = azurerm_nat_gateway.studio[each.value.virtualNetworkKey].id
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
    for virtualNetwork in local.natGatewayNetworks : virtualNetwork.key => virtualNetwork
  }
  name                = "Gateway-NAT"
  resource_group_name = each.value.resourceGroupName
  location            = each.value.regionName
  sku                 = var.natGateway.ipAddress.type
  sku_tier            = var.natGateway.ipAddress.tier
  prefix_length       = 31
  depends_on = [
    azurerm_resource_group.network_regions
  ]
}

resource azurerm_nat_gateway_public_ip_prefix_association studio {
  for_each = {
    for virtualNetwork in local.natGatewayNetworks : virtualNetwork.key => virtualNetwork
  }
  nat_gateway_id      = azurerm_nat_gateway.studio[each.value.key].id
  public_ip_prefix_id = azurerm_public_ip_prefix.nat_gateway[each.value.key].id
}
