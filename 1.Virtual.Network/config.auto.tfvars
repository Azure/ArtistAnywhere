resourceGroupName = "ArtistAnywhere.Network" # Alphanumeric, underscores, hyphens, periods and parenthesis are allowed

#################################################################################################
# Virtual Network (https://learn.microsoft.com/azure/virtual-network/virtual-networks-overview) #
#################################################################################################

virtualNetworks = [
  {
    enable     = true
    name       = "Studio"
    regionName = ""
    addressSpace = [
      "10.0.0.0/16"
    ]
    dnsAddresses = [
    ]
    subnets = [
      {
        name = "Farm"
        addressSpace = [
          "10.0.0.0/17"
        ]
        serviceDelegation = null
      },
      {
        name = "Workstation"
        addressSpace = [
          "10.0.128.0/18"
        ]
        serviceDelegation = null
      },
      {
        name = "Storage"
        addressSpace = [
          "10.0.192.0/24"
        ]
        serviceDelegation = null
      },
      {
        name = "StorageHA"
        addressSpace = [
          "10.0.201.0/28"
        ]
        serviceDelegation = null
      },
      {
        name = "StorageNetApp"
        addressSpace = [
          "10.0.193.0/24"
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
          "10.0.194.0/24"
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
          "10.0.195.0/24"
        ]
        serviceDelegation = null
      },
      {
        name = "DataPostgreSQL"
        addressSpace = [
          "10.0.196.0/24"
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
          "10.0.197.0/24"
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
          "10.0.198.0/24"
        ]
        serviceDelegation = null
      },
      {
        name = "CacheHA"
        addressSpace = [
          "10.0.202.0/28"
        ]
        serviceDelegation = null
      },
      {
        name = "App"
        addressSpace = [
          "10.0.199.0/24"
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
          "10.0.200.0/24"
        ]
        serviceDelegation = {
          service = "Microsoft.Web/serverFarms"
          actions = [
            "Microsoft.Network/virtualNetworks/subnets/action"
          ]
        }
      },
      {
        name = "GatewaySubnet"
        addressSpace = [
          "10.0.255.0/26"
        ]
        serviceDelegation = null
      },
      {
        name = "AzureBastionSubnet"
        addressSpace = [
          "10.0.255.64/26"
        ]
        serviceDelegation = null
      }
    ]
  },
  {
    enable     = false
    name       = "Studio"
    regionName = "WestUS"
    addressSpace = [
      "10.1.0.0/16"
    ]
    dnsAddresses = [
    ]
    subnets = [
      {
        name = "Farm"
        addressSpace = [
          "10.1.0.0/17"
        ]
        serviceDelegation = null
      },
      {
        name = "Workstation"
        addressSpace = [
          "10.1.128.0/18"
        ]
        serviceDelegation = null
      },
      {
        name = "Storage"
        addressSpace = [
          "10.1.192.0/24"
        ]
        serviceDelegation = null
      },
      {
        name = "StorageHA"
        addressSpace = [
          "10.1.201.0/28"
        ]
        serviceDelegation = null
      },
      {
        name = "StorageNetApp"
        addressSpace = [
          "10.1.193.0/24"
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
          "10.1.194.0/24"
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
          "10.1.195.0/24"
        ]
        serviceDelegation = null
      },
      {
        name = "DataPostgreSQL"
        addressSpace = [
          "10.1.196.0/24"
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
          "10.1.197.0/24"
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
          "10.1.198.0/24"
        ]
        serviceDelegation = null
      },
      {
        name = "CacheHA"
        addressSpace = [
          "10.1.202.0/28"
        ]
        serviceDelegation = null
      },
      {
        name = "App"
        addressSpace = [
          "10.1.199.0/24"
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
          "10.1.200.0/24"
        ]
        serviceDelegation = {
          service = "Microsoft.Web/serverFarms"
          actions = [
            "Microsoft.Network/virtualNetworks/subnets/action"
          ]
        }
      },
      {
        name = "GatewaySubnet"
        addressSpace = [
          "10.1.255.0/26"
        ]
        serviceDelegation = null
      },
      {
        name = "AzureBastionSubnet"
        addressSpace = [
          "10.1.255.64/26"
        ]
        serviceDelegation = null
      }
    ]
  }
]

############################################################################
# Private DNS (https://learn.microsoft.com/azure/dns/private-dns-overview) #
############################################################################

privateDns = {
  zoneName = "azure.studio"
  autoRegistration = {
    enable = true
  }
}

########################################################################
# Bastion (https://learn.microsoft.com/azure/bastion/bastion-overview) #
########################################################################

bastion = {
  enable              = true
  tier                = "Standard"
  scaleUnitCount      = 2
  enableFileCopy      = true
  enableCopyPaste     = true
  enableIpConnect     = true
  enableTunneling     = true
  enablePerRegion     = true
  enableShareableLink = false
}

################################################################################################################
# Virtual Network Peering (https://learn.microsoft.com/azure/virtual-network/virtual-network-peering-overview) #
################################################################################################################

networkPeering = {
  enable                      = false
  allowRemoteNetworkAccess    = true
  allowRemoteForwardedTraffic = true
  allowGatewayTransit         = true
  useRemoteGateways = {
    compute = false
    storage = false
  }
}
