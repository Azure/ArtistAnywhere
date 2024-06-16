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
  resource_group_name = data.azurerm_resource_group.network.name
  location            = data.azurerm_resource_group.network.location
  edge_zone           = var.virtualNetwork.edgeZoneName != "" ? var.virtualNetwork.edgeZoneName : null
  type                = "Vpn"
  sku                 = var.vpnGateway.tier
  vpn_type            = var.vpnGateway.type
  generation          = var.vpnGateway.generation
  enable_bgp          = var.vpnGateway.enableBgp
  active_active       = var.virtualNetwork.gateway.ipAddress2.name != ""
  ip_configuration {
    name                 = "ipConfig1"
    subnet_id            = "/subscriptions/${data.azurerm_client_config.studio.subscription_id}/resourceGroups/${var.virtualNetwork.resourceGroupName}/providers/Microsoft.Network/virtualNetworks/${var.virtualNetwork.name}/subnets/GatewaySubnet"
    public_ip_address_id = "/subscriptions/${data.azurerm_client_config.studio.subscription_id}/resourceGroups/${var.virtualNetwork.gateway.ipAddress1.resourceGroupName}/providers/Microsoft.Network/publicIPAddresses/${var.virtualNetwork.gateway.ipAddress1.name}"
  }
  dynamic ip_configuration {
    for_each = var.virtualNetwork.gateway.ipAddress2.name != "" ? [1] : []
    content {
      name                 = "ipConfig2"
      subnet_id            = "/subscriptions/${data.azurerm_client_config.studio.subscription_id}/resourceGroups/${var.virtualNetwork.resourceGroupName}/providers/Microsoft.Network/virtualNetworks/${var.virtualNetwork.name}/subnets/GatewaySubnet"
      public_ip_address_id = "/subscriptions/${data.azurerm_client_config.studio.subscription_id}/resourceGroups/${var.virtualNetwork.gateway.ipAddress2.resourceGroupName}/providers/Microsoft.Network/publicIPAddresses/${var.virtualNetwork.gateway.ipAddress2.name}"
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
