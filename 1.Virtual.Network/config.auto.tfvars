resourceGroupName = "ArtistAnywhere.Network" # Alphanumeric, underscores, hyphens, periods and parenthesis are allowed

#################################################################################################
# Virtual Network (https://learn.microsoft.com/azure/virtual-network/virtual-networks-overview) #
#################################################################################################

virtualNetworks = [
  {
    enable   = true
    name     = "Studio"
    location = "SouthCentralUS"
    addressSpace = [
      "10.0.0.0/16"
    ]
    dnsAddresses = [
    ]
    subnets = [
      {
        name = "Cluster"
        addressSpace = [
          "10.0.0.0/17"
        ]
        serviceEndpoints = [
          "Microsoft.Storage"
        ]
        serviceDelegation = null
      },
      {
        name = "Workstation"
        addressSpace = [
          "10.0.128.0/18"
        ]
        serviceEndpoints = [
        ]
        serviceDelegation = null
      },
      {
        name = "Identity"
        addressSpace = [
          "10.0.192.0/24"
        ]
        serviceEndpoints = [
        ]
        serviceDelegation = null
      },
      {
        name = "Storage"
        addressSpace = [
          "10.0.193.0/24"
        ]
        serviceEndpoints = [
          "Microsoft.Storage"
        ]
        serviceDelegation = null
      },
      {
        name = "StorageNetApp"
        addressSpace = [
          "10.0.194.0/24"
        ]
        serviceEndpoints = [
        ]
        serviceDelegation = {
          service = "Microsoft.Netapp/volumes"
          actions = [
            "Microsoft.Network/networkinterfaces/*",
            "Microsoft.Network/virtualNetworks/subnets/join/action"
          ]
        }
      },
      {
        name = "StorageQumulo"
        addressSpace = [
          "10.0.195.0/24"
        ]
        serviceEndpoints = [
        ]
        serviceDelegation = {
          service = "Qumulo.Storage/fileSystems"
          actions = [
            "Microsoft.Network/virtualNetworks/subnets/join/action"
          ]
        }
      },
      {
        name = "Data"
        addressSpace = [
          "10.0.196.0/24"
        ]
        serviceEndpoints = [
        ]
        serviceDelegation = null
      },
      {
        name = "DataMySQL"
        addressSpace = [
          "10.0.197.0/24"
        ]
        serviceEndpoints = [
        ]
        serviceDelegation = {
          service = "Microsoft.DBforMySQL/flexibleServers"
          actions = [
            "Microsoft.Network/virtualNetworks/subnets/join/action"
          ]
        }
      },
      {
        name = "DataPostgreSQL"
        addressSpace = [
          "10.0.198.0/24"
        ]
        serviceEndpoints = [
        ]
        serviceDelegation = {
          service = "Microsoft.DBforPostgreSQL/flexibleServers"
          actions = [
            "Microsoft.Network/virtualNetworks/subnets/join/action"
          ]
        }
      },
      {
        name = "DataCassandra"
        addressSpace = [
          "10.0.199.0/24"
        ]
        serviceEndpoints = [
        ]
        serviceDelegation = {
          service = "Microsoft.DocumentDB/cassandraClusters"
          actions = [
            "Microsoft.Network/virtualNetworks/subnets/join/action"
          ]
        }
      },
      {
        name = "Cache"
        addressSpace = [
          "10.0.200.0/24"
        ]
        serviceEndpoints = [
        ]
        serviceDelegation = null
      },
      {
        name = "App"
        addressSpace = [
          "10.0.201.0/24"
        ]
        serviceEndpoints = [
        ]
        serviceDelegation = {
          service = "Microsoft.App/environments"
          actions = [
            "Microsoft.Network/virtualNetworks/subnets/join/action"
          ]
        }
      },
      {
        name = "Web"
        addressSpace = [
          "10.0.202.0/24"
        ]
        serviceEndpoints = [
          "Microsoft.Storage"
        ]
        serviceDelegation = null
      },
      {
        name = "GatewaySubnet"
        addressSpace = [
          "10.0.254.0/25"
        ]
        serviceEndpoints = [
        ]
        serviceDelegation = null
      },
      {
        name = "AzureBastionSubnet"
        addressSpace = [
          "10.0.254.128/25"
        ]
        serviceEndpoints = [
        ]
        serviceDelegation = null
      },
      {
        name = "AzureFirewallSubnet"
        addressSpace = [
          "10.0.255.0/25"
        ]
        serviceEndpoints = [
        ]
        serviceDelegation = null
      },
      {
        name = "AzureFirewallManagementSubnet"
        addressSpace = [
          "10.0.255.128/25"
        ]
        serviceEndpoints = [
        ]
        serviceDelegation = null
      }
    ]
  }
]

virtualNetworksAdded = [ # Optional additional virtual networks
  {
    enable   = false
    location = "WestUS"
    addressSpace = {
      search  = "10.0"
      replace = "10.1"
    }
    extendedZone = {
      enable   = false
      name     = ""
      location = ""
    }
  },
  {
    enable   = false
    location = "WestUS"
    addressSpace = {
      search  = "10.0"
      replace = "10.2"
    }
    extendedZone = {
      enable   = true
      name     = "LosAngeles"
      location = "WestUS"
    }
  },
  {
    enable   = false
    location = "WestUS3"
    addressSpace = {
      search  = "10.0"
      replace = "10.3"
    }
    extendedZone = {
      enable   = false
      name     = ""
      location = ""
    }
  }
]

############################################################################
# Private DNS (https://learn.microsoft.com/azure/dns/private-dns-overview) #
############################################################################

privateDNS = {
  zoneName = "azure.studio"
  autoRegistration = {
    enable = true
  }
}

##################################################################
# Firewall (https://learn.microsoft.com/azure/firewall/overview) #
##################################################################

firewall = {
  enable = false
  name   = "xstudio"
  type   = "AZFW_VNet"
  tier   = "Standard"
}

########################################################################
# Bastion (https://learn.microsoft.com/azure/bastion/bastion-overview) #
########################################################################

bastion = {
  enable              = true
  type                = "Standard"
  scaleUnitCount      = 2
  enableFileCopy      = true
  enableCopyPaste     = true
  enableIpConnect     = true
  enableTunneling     = true
  enablePerRegion     = false
  enableShareableLink = false
  enableSessionRecord = false
}

##########################################################################################################################
# Network Address Translation (NAT) Gateway (https://learn.microsoft.com/azure/virtual-network/nat-gateway/nat-overview) #
##########################################################################################################################

natGateway = {
  enable = true
  ipAddress = {
    tier = "Standard"
    type = "Regional"
  }
}

################################################################################################################
# Virtual Network Peering (https://learn.microsoft.com/azure/virtual-network/virtual-network-peering-overview) #
################################################################################################################

networkPeering = {
  enable                      = false
  allowRemoteNetworkAccess    = true
  allowRemoteForwardedTraffic = true
  allowGatewayTransit         = true
  useRemoteGateway = {
    computeNetwork = false
    storageNetwork = false
  }
}
