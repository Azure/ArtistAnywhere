################################################################################################################
# Virtual Network Peering (https://learn.microsoft.com/azure/virtual-network/virtual-network-peering-overview) #
################################################################################################################

variable networkPeering {
  type = object({
    enable                      = bool
    allowRemoteNetworkAccess    = bool
    allowRemoteForwardedTraffic = bool
    allowGatewayTransit         = bool
    useRemoteGateway = object({
      computeNetwork = bool
      storageNetwork = bool
    })
  })
}

resource azurerm_virtual_network_peering compute {
  count                        = var.networkPeering.enable ? length(local.virtualNetworks) - 1 : 0
  name                         = "${local.virtualNetworks[count.index + 1].name}-${local.virtualNetworks[count.index + 1].regionName}.${local.virtualNetworks[count.index].name}-${local.virtualNetworks[count.index].regionName}"
  resource_group_name          = local.virtualNetworks[count.index + 1].resourceGroupName
  virtual_network_name         = local.virtualNetworks[count.index + 1].name
  remote_virtual_network_id    = local.virtualNetworks[count.index].id
  allow_virtual_network_access = var.networkPeering.allowRemoteNetworkAccess
  allow_forwarded_traffic      = var.networkPeering.allowRemoteForwardedTraffic
  allow_gateway_transit        = var.networkPeering.allowGatewayTransit
  use_remote_gateways          = var.networkPeering.useRemoteGateway.computeNetwork
  depends_on = [
    azurerm_subnet_network_security_group_association.studio
  ]
}

resource azurerm_virtual_network_peering storage {
  count                        = var.networkPeering.enable ? length(local.virtualNetworks) - 1 : 0
  name                         = "${local.virtualNetworks[count.index].name}-${local.virtualNetworks[count.index].regionName}.${local.virtualNetworks[count.index + 1].name}-${local.virtualNetworks[count.index + 1].regionName}"
  resource_group_name          = local.virtualNetworks[count.index].resourceGroupName
  virtual_network_name         = local.virtualNetworks[count.index].name
  remote_virtual_network_id    = local.virtualNetworks[count.index + 1].id
  allow_virtual_network_access = var.networkPeering.allowRemoteNetworkAccess
  allow_forwarded_traffic      = var.networkPeering.allowRemoteForwardedTraffic
  allow_gateway_transit        = var.networkPeering.allowGatewayTransit
  use_remote_gateways          = var.networkPeering.useRemoteGateway.storageNetwork
  depends_on = [
    azurerm_subnet_network_security_group_association.studio
  ]
}
