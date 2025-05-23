##########################################################################################################################
# Network Address Translation (NAT) Gateway (https://learn.microsoft.com/azure/virtual-network/nat-gateway/nat-overview) #
##########################################################################################################################

variable natGateway {
  type = object({
    enable = bool
    name   = string
    ipAddress = object({
      tier = string
      type = string
    })
  })
}

locals {
  natGatewayNetworks = [
    for virtualNetwork in local.virtualNetworks : virtualNetwork if var.natGateway.enable && try(virtualNetwork.extendedZone.name, "") == ""
  ]
  natGatewayNetworksSubnets = flatten([
    for virtualNetwork in local.natGatewayNetworks : [
      for subnet in virtualNetwork.subnets : merge(subnet, {
        key            = "${virtualNetwork.key}-${subnet.name}"
        virtualNetwork = virtualNetwork
      }) if subnet.name != "GatewaySubnet" && try(virtualNetwork.extendedZone.name, "") == ""
    ]
  ])
}

resource azurerm_nat_gateway main {
  for_each = {
    for virtualNetwork in local.natGatewayNetworks : virtualNetwork.key => virtualNetwork
  }
  name                = var.natGateway.name
  resource_group_name = each.value.resourceGroup.name
  location            = each.value.location
  depends_on = [
    azurerm_resource_group.network_regions
  ]
}

resource azurerm_subnet_nat_gateway_association main {
  for_each = {
    for subnet in local.natGatewayNetworksSubnets : subnet.key => subnet
  }
  nat_gateway_id = azurerm_nat_gateway.main[each.value.virtualNetwork.key].id
  subnet_id      = "${each.value.virtualNetwork.id}/subnets/${each.value.name}"
  depends_on = [
    azurerm_subnet.main
  ]
}

######################################################################################################################
# Public IP Address Prefix (https://learn.microsoft.com/azure/virtual-network/ip-services/public-ip-address-prefix ) #
######################################################################################################################

resource azurerm_public_ip_prefix nat_gateway {
  for_each = {
    for virtualNetwork in local.natGatewayNetworks : virtualNetwork.key => virtualNetwork
  }
  name                = var.natGateway.name
  resource_group_name = each.value.resourceGroup.name
  location            = each.value.location
  sku                 = var.natGateway.ipAddress.tier
  sku_tier            = var.natGateway.ipAddress.type
  prefix_length       = 31
  depends_on = [
    azurerm_resource_group.network_regions
  ]
}

resource azurerm_nat_gateway_public_ip_prefix_association main {
  for_each = {
    for virtualNetwork in local.natGatewayNetworks : virtualNetwork.key => virtualNetwork
  }
  nat_gateway_id      = azurerm_nat_gateway.main[each.value.key].id
  public_ip_prefix_id = azurerm_public_ip_prefix.nat_gateway[each.value.key].id
}
