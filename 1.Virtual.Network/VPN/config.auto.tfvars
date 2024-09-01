subscriptionId = "" # Set to your Azure subscription id

###############################################################################################################
# Virtual Network Gateway (VPN) (https://learn.microsoft.com/azure/vpn-gateway/vpn-gateway-about-vpngateways) #
###############################################################################################################

vpnGateway = {
  name       = "Gateway-VPN"
  tier       = "VpnGw2"
  type       = "RouteBased"
  generation = "Generation2"
  sharedKey  = ""
  enableBgp  = false
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
  enable  = false
  fqdn    = "" # Set the fully-qualified domain name (FQDN) of your on-premises VPN gateway device
  address = "" # or set the device public IP address. Do NOT set both configuration parameters.
  addressSpace = [
  ]
  bgp = {
    enable         = false
    asn            = 0
    peerWeight     = 0
    peeringAddress = ""
  }
}

#################################################################################################
# Virtual Network (https://learn.microsoft.com/azure/virtual-network/virtual-networks-overview) #
#################################################################################################

virtualNetwork = {
  name              = "Studio"
  extendedZoneName  = ""
  resourceGroupName = "ArtistAnywhere.Network.WestUS"
  gateway = {
    ipAddress1 = {
      name              = "xstudio"
      resourceGroupName = "Shared"
    }
    ipAddress2 = {
      name              = ""
      resourceGroupName = ""
    }
  }
}
