##########################################################################################################################
# Local Network Gateway (VPN) (https://learn.microsoft.com/azure/vpn-gateway/vpn-gateway-about-vpn-gateway-settings#lng) #
##########################################################################################################################

variable vpnGatewayLocal {
  type = object({
    enable       = bool
    fqdn         = string
    address      = string
    addressSpace = list(string)
    bgp = object({
      enable         = bool
      asn            = number
      peerWeight     = number
      peeringAddress = string
    })
  })
  validation {
    condition     = !var.vpnGatewayLocal.enable || (var.vpnGatewayLocal.fqdn != "" && var.vpnGatewayLocal.address == "") || (var.vpnGatewayLocal.fqdn == "" && var.vpnGatewayLocal.address != "")
    error_message = "Either the vpnGatewayLocal.fqdn config or the vpnGatewayLocal.address config must be specified, but not both."
  }
}

resource azurerm_local_network_gateway vpn {
  count               = var.vpnGatewayLocal.enable ? 1 : 0
  name                = azurerm_virtual_network_gateway.vpn.name
  resource_group_name = data.azurerm_virtual_network.studio.resource_group_name
  location            = data.azurerm_virtual_network.studio.location
  gateway_fqdn        = var.vpnGatewayLocal.address == "" ? var.vpnGatewayLocal.fqdn : null
  gateway_address     = var.vpnGatewayLocal.fqdn == "" ? var.vpnGatewayLocal.address : null
  address_space       = var.vpnGatewayLocal.addressSpace
  dynamic bgp_settings {
    for_each = var.vpnGatewayLocal.bgp.enable ? [1] : []
    content {
      asn                 = var.vpnGatewayLocal.bgp.asn
      peer_weight         = var.vpnGatewayLocal.bgp.peerWeight
      bgp_peering_address = var.vpnGatewayLocal.bgp.peeringAddress
    }
  }
}

resource azurerm_virtual_network_gateway_connection site_to_site {
  count                      = var.vpnGatewayLocal.enable ? 1 : 0
  name                       = azurerm_virtual_network_gateway.vpn.name
  resource_group_name        = data.azurerm_virtual_network.studio.resource_group_name
  location                   = data.azurerm_virtual_network.studio.location
  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vpn.id
  local_network_gateway_id   = azurerm_local_network_gateway.vpn[0].id
  shared_key                 = var.vpnGateway.sharedKey
  enable_bgp                 = var.vpnGatewayLocal.bgp.enable
}
