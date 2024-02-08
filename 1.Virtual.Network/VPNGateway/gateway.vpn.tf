###############################################################################################################
# Virtual Network Gateway (VPN) (https://learn.microsoft.com/azure/vpn-gateway/vpn-gateway-about-vpngateways) #
###############################################################################################################

variable vpnGateway {
  type = object({
    sku                = string
    type               = string
    generation         = string
    sharedKey          = string
    enableBgp          = bool
    enablePerRegion    = bool
    enableActiveActive = bool
    pointToSiteClient = object({
      addressSpace = list(string)
      rootCertificate = object({
        name = string
        data = string
      })
    })
  })
}

variable vpnGatewayLocal {
  type = object({
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
}

resource azurerm_virtual_network_gateway vpn {
  name                = "Gateway-VPN"
  resource_group_name = azurerm_resource_group.network.name
  location            = azurerm_resource_group.network.location
  type                = "Vpn"
  sku                 = var.vpnGateway.sku
  vpn_type            = var.vpnGateway.type
  generation          = var.vpnGateway.generation
  enable_bgp          = var.vpnGateway.enableBgp
  active_active       = var.vpnGateway.enableActiveActive
  ip_configuration {
    name                 = "ipConfig1"
    public_ip_address_id = azurerm_public_ip.vpn_gateway_1.id
    subnet_id            = "/subscriptions/${data.azurerm_client_config.studio.subscription_id}/resourceGroups/${var.virtualNetwork.resourceGroupName}/providers/Microsoft.Network/virtualNetworks/${var.virtualNetwork.name}/subnets/GatewaySubnet"
  }
  dynamic ip_configuration {
    for_each = var.vpnGateway.enableActiveActive ? [1] : []
    content {
      name                 = "ipConfig2"
      public_ip_address_id = azurerm_public_ip.vpn_gateway_2[0].id
      subnet_id            = "/subscriptions/${data.azurerm_client_config.studio.subscription_id}/resourceGroups/${var.virtualNetwork.resourceGroupName}/providers/Microsoft.Network/virtualNetworks/${var.virtualNetwork.name}/subnets/GatewaySubnet"
    }
  }
  dynamic vpn_client_configuration {
    for_each = length(var.vpnGateway.pointToSiteClient.addressSpace) > 0 ? [1] : []
    content {
      address_space = var.vpnGateway.pointToSiteClient.addressSpace
      root_certificate {
        name             = var.vpnGateway.pointToSiteClient.rootCertificate.name
        public_cert_data = var.vpnGateway.pointToSiteClient.rootCertificate.data
      }
    }
  }
  depends_on = [
    azurerm_public_ip.vpn_gateway_1,
    azurerm_public_ip.vpn_gateway_2
  ]
}

##########################################################################################################################
# Local Network Gateway (VPN) (https://learn.microsoft.com/azure/vpn-gateway/vpn-gateway-about-vpn-gateway-settings#lng) #
##########################################################################################################################

resource azurerm_local_network_gateway vpn {
  name                = var.virtualNetwork.name
  resource_group_name = azurerm_resource_group.network.name
  location            = azurerm_resource_group.network.location
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
  name                       = var.virtualNetwork.name
  resource_group_name        = azurerm_resource_group.network.name
  location                   = azurerm_resource_group.network.location
  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vpn.id
  local_network_gateway_id   = azurerm_local_network_gateway.vpn.id
  shared_key                 = var.vpnGateway.sharedKey
  enable_bgp                 = var.vpnGatewayLocal.bgp.enable
}
