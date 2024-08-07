resourceGroupName = "ArtistAnywhere.Network" # Alphanumeric, underscores, hyphens, periods and parenthesis are allowed

#################################################################################################
# Virtual Network (https://learn.microsoft.com/azure/virtual-network/virtual-networks-overview) #
#################################################################################################

virtualNetworks = [
  {
    enable = true
    name   = "Studio"
    regionNames = [
    ]
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
        serviceEndpoints = [
          "Microsoft.Storage.Global",
          "Microsoft.ContainerRegistry"
        ]
        serviceDelegation = null
      },
      {
        name = "Workstation"
        addressSpace = [
          "10.0.128.0/18"
        ]
        serviceEndpoints = [
          "Microsoft.Storage.Global"
        ]
        serviceDelegation = null
      },
      {
        name = "Storage"
        addressSpace = [
          "10.0.192.0/25"
        ]
        serviceEndpoints = [
          "Microsoft.Storage.Global"
        ]
        serviceDelegation = null
      },
      {
        name = "Storage2"
        addressSpace = [
          "10.0.192.128/25"
        ]
        serviceEndpoints = [
          "Microsoft.Storage.Global"
        ]
        serviceDelegation = null
      },
      {
        name = "StorageNetApp"
        addressSpace = [
          "10.0.193.0/24"
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
          "10.0.194.0/24"
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
          "10.0.195.0/24"
        ]
        serviceEndpoints = [
        ]
        serviceDelegation = null
      },
      {
        name = "DataCassandra"
        addressSpace = [
          "10.0.196.0/24"
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
          "10.0.197.0/24"
        ]
        serviceEndpoints = [
          "Microsoft.Storage.Global"
        ]
        serviceDelegation = null
      },
      {
        name = "AI"
        addressSpace = [
          "10.0.198.0/24"
        ]
        serviceEndpoints = [
          "Microsoft.CognitiveServices"
        ]
        serviceDelegation = null
      },
      {
        name = "API"
        addressSpace = [
          "10.0.199.0/24"
        ]
        serviceEndpoints = [
        ]
        serviceDelegation = null
      },
      {
        name = "GatewaySubnet"
        addressSpace = [
          "10.0.255.0/26"
        ]
        serviceEndpoints = [
        ]
        serviceDelegation = null
      },
      {
        name = "AzureBastionSubnet"
        addressSpace = [
          "10.0.255.64/26"
        ]
        serviceEndpoints = [
        ]
        serviceDelegation = null
      }
    ]
  },
  {
    enable = false
    name   = "Studio"
    regionNames = [
      "EastUS"
    ]
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
        serviceEndpoints = [
          "Microsoft.Storage.Global",
          "Microsoft.ContainerRegistry"
        ]
        serviceDelegation = null
      },
      {
        name = "Workstation"
        addressSpace = [
          "10.1.128.0/18"
        ]
        serviceEndpoints = [
          "Microsoft.Storage.Global"
        ]
        serviceDelegation = null
      },
      {
        name = "Storage"
        addressSpace = [
          "10.1.192.0/25"
        ]
        serviceEndpoints = [
          "Microsoft.Storage.Global"
        ]
        serviceDelegation = null
      },
      {
        name = "Storage2"
        addressSpace = [
          "10.1.192.128/25"
        ]
        serviceEndpoints = [
          "Microsoft.Storage.Global"
        ]
        serviceDelegation = null
      },
      {
        name = "StorageNetApp"
        addressSpace = [
          "10.1.193.0/24"
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
          "10.1.194.0/24"
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
          "10.1.195.0/24"
        ]
        serviceEndpoints = [
        ]
        serviceDelegation = null
      },
      {
        name = "DataCassandra"
        addressSpace = [
          "10.1.196.0/24"
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
          "10.1.197.0/24"
        ]
        serviceEndpoints = [
          "Microsoft.Storage.Global"
        ]
        serviceDelegation = null
      },
      {
        name = "AI"
        addressSpace = [
          "10.1.198.0/24"
        ]
        serviceEndpoints = [
          "Microsoft.CognitiveServices"
        ]
        serviceDelegation = null
      },
      {
        name = "API"
        addressSpace = [
          "10.0.199.0/24"
        ]
        serviceEndpoints = [
        ]
        serviceDelegation = null
      },
      {
        name = "GatewaySubnet"
        addressSpace = [
          "10.1.255.0/26"
        ]
        serviceEndpoints = [
        ]
        serviceDelegation = null
      },
      {
        name = "AzureBastionSubnet"
        addressSpace = [
          "10.1.255.64/26"
        ]
        serviceEndpoints = [
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
  zoneName = "artist.studio"
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
  enablePerRegion     = false
  enableShareableLink = false
}

######################################################################
# Monitor (https://learn.microsoft.com/azure/azure-monitor/overview) #
######################################################################

monitor = {
  enable = true
}

#################################################
# Non-Default Terraform Workspace Configuration #
#################################################

subscriptionId = {
  terraformState = ""
}
