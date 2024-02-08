resourceGroupName = "ArtistAnywhere.Network" # Alphanumeric, underscores, hyphens, periods and parenthesis are allowed

regionName = "" # Set Azure region name from "az account list-locations --query [].name"

#################################################################################################
# Virtual Network (https://learn.microsoft.com/azure/virtual-network/virtual-networks-overview) #
#################################################################################################

virtualNetwork = {
  name              = ""
  resourceGroupName = ""
}

###############################################################################################################
# Virtual Network Gateway (VPN) (https://learn.microsoft.com/azure/vpn-gateway/vpn-gateway-about-vpngateways) #
###############################################################################################################

vpnGateway = {
  enable             = false
  sku                = "VpnGw2"
  type               = "RouteBased"
  generation         = "Generation2"
  sharedKey          = ""
  enableBgp          = false
  enablePerRegion    = false
  enableActiveActive = false
  pointToSiteClient = {
    addressSpace = [
    ]
    rootCertificate = {
      name = ""
      data = ""
    }
  }
}

##########################################################################################################################
# Local Network Gateway (VPN) (https://learn.microsoft.com/azure/vpn-gateway/vpn-gateway-about-vpn-gateway-settings#lng) #
##########################################################################################################################

vpnGatewayLocal = {
  fqdn    = "" # Set the fully-qualified domain name (FQDN) of your on-premises VPN gateway device
  address = "" # or set the public IP address. Do NOT set both "fqdn" and "address" parameters
  addressSpace = [
  ]
  bgp = {
    enable         = false
    asn            = 0
    peerWeight     = 0
    peeringAddress = ""
  }
}
