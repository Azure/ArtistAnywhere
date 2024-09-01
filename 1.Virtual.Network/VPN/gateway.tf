###############################################################################################################
# Virtual Network Gateway (VPN) (https://learn.microsoft.com/azure/vpn-gateway/vpn-gateway-about-vpngateways) #
###############################################################################################################

variable vpnGateway {
  type = object({
    name       = string
    tier       = string
    type       = string
    generation = string
    sharedKey  = string
    enableBgp  = bool
    pointToSiteClient = object({
      addressSpace = list(string)
      rootCertificate = object({
        name = string
        data = string
      })
    })
  })
}

resource azurerm_virtual_network_gateway vpn {
  name                = var.vpnGateway.name
  resource_group_name = data.azurerm_virtual_network.studio.resource_group_name
  location            = data.azurerm_virtual_network.studio.location
  edge_zone           = var.virtualNetwork.extendedZoneName != "" ? var.virtualNetwork.extendedZoneName : null
  type                = "Vpn"
  sku                 = var.vpnGateway.tier
  vpn_type            = var.vpnGateway.type
  generation          = var.vpnGateway.generation
  enable_bgp          = var.vpnGateway.enableBgp
  active_active       = var.virtualNetwork.gateway.ipAddress2.name != ""
  ip_configuration {
    name                 = "ipConfig1"
    subnet_id            = data.azurerm_subnet.gateway.id
    public_ip_address_id = data.azurerm_public_ip.gateway1.id
  }
  dynamic ip_configuration {
    for_each = var.virtualNetwork.gateway.ipAddress2.name != "" ? [1] : []
    content {
      name                 = "ipConfig2"
      subnet_id            = data.azurerm_subnet.gateway.id
      public_ip_address_id = data.azurerm_public_ip.gateway2[0].id
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
}
