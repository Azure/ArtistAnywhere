resourceGroupName = "AAA.Network"

#################################################################################################
# Virtual Network (https://learn.microsoft.com/azure/virtual-network/virtual-networks-overview) #
#################################################################################################

virtualNetworks = [
  {
    enable   = true
    name     = "HPC"
    hubName  = "USCentral"
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
        name = "VDI"
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
        name = "Data"
        addressSpace = [
          "10.0.195.0/24"
        ]
        serviceEndpoints = [
        ]
        serviceDelegation = null
      },
      {
        name = "DataMySQL"
        addressSpace = [
          "10.0.196.0/24"
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
          "10.0.197.0/24"
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
          "10.0.198.0/24"
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
          "10.0.199.0/24"
        ]
        serviceEndpoints = [
        ]
        serviceDelegation = null
      },
      {
        name = "App"
        addressSpace = [
          "10.0.200.0/23"
        ]
        serviceEndpoints = [
        ]
        serviceDelegation = null
      },
      {
        name = "AppCPU"
        addressSpace = [
          "10.0.202.0/24"
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
        name = "AppGPU"
        addressSpace = [
          "10.0.203.0/24"
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
          "10.0.204.0/24"
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
      # {
      #   name = "AzureFirewallSubnet"
      #   addressSpace = [
      #     "10.0.255.0/25"
      #   ]
      #   serviceEndpoints = [
      #   ]
      #   serviceDelegation = null
      # },
      # {
      #   name = "AzureFirewallManagementSubnet"
      #   addressSpace = [
      #     "10.0.255.128/25"
      #   ]
      #   serviceEndpoints = [
      #   ]
      #   serviceDelegation = null
      # }
    ]
  }
]

virtualNetworksExtended = [
  {
    enable   = true
    hubName  = "USWest"
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
    enable   = true
    hubName  = "USWest"
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
    enable   = true
    hubName  = "USWest"
    location = "WestUS2"
    addressSpace = {
      search  = "10.0"
      replace = "10.3"
    }
    extendedZone = {
      enable   = false
      name     = ""
      location = ""
    }
  },
  {
    enable   = true
    hubName  = "USWest"
    location = "WestUS3"
    addressSpace = {
      search  = "10.0"
      replace = "10.4"
    }
    extendedZone = {
      enable   = false
      name     = ""
      location = ""
    }
  },
  {
    enable   = false
    hubName  = "USEast"
    location = "EastUS"
    addressSpace = {
      search  = "10.0"
      replace = "10.5"
    }
    extendedZone = {
      enable   = false
      name     = ""
      location = ""
    }
  },
  {
    enable   = false
    hubName  = "USEast"
    location = "EastUS2"
    addressSpace = {
      search  = "10.0"
      replace = "10.6"
    }
    extendedZone = {
      enable   = false
      name     = ""
      location = ""
    }
  },
  {
    enable   = false
    hubName  = "USEast"
    location = "EastUS3"
    addressSpace = {
      search  = "10.0"
      replace = "10.7"
    }
    extendedZone = {
      enable   = false
      name     = ""
      location = ""
    }
  }
]

#################################################################################
# Virtual WAN (https://learn.microsoft.com/azure/virtual-wan/virtual-wan-about) #
#################################################################################

virtualWAN = {
  enable = true
  name   = "hpcai"
  type   = "Standard"
  hubs = [
    {
      enable       = true
      name         = "USWest"
      type         = "Standard"
      location     = "WestUS"
      addressSpace = "10.10.0.0/24"
      router = {
        preferenceMode = "ExpressRoute"
        scaleUnit = {
          minCount = 2
        }
        routes = [
          {
            enable      = false
            name        = ""
            nextAddress = ""
            addressSpace = [
            ]
          }
        ]
      }
    },
    {
      enable       = true
      name         = "USCentral"
      type         = "Standard"
      location     = "SouthCentralUS"
      addressSpace = "10.11.0.0/24"
      router = {
        preferenceMode = "ExpressRoute"
        scaleUnit = {
          minCount = 2
        }
        routes = [
          {
            enable      = false
            name        = ""
            nextAddress = ""
            addressSpace = [
            ]
          }
        ]
      }
    },
    {
      enable       = false
      name         = "USEast"
      type         = "Standard"
      location     = "EastUS"
      addressSpace = "10.12.0.0/24"
      router = {
        preferenceMode = "ExpressRoute"
        scaleUnit = {
          minCount = 2
        }
        routes = [
          {
            enable      = false
            name        = ""
            nextAddress = ""
            addressSpace = [
            ]
          }
        ]
      }
    }
  ]
}

#############################################################################################
# VPN Gateway (https://learn.microsoft.com/azure/vpn-gateway/vpn-gateway-about-vpngateways) #
#############################################################################################

vpnGateway = {
  enable = true
  name   = "hpcai"
  sites = [
    {
      enable     = true
      name       = "uscentral"
      hubName    = "USCentral"
      scaleUnits = 1
      siteToSite = {
        enable = false
        addressSpace = [
          "10.20.0.0/24"
        ]
        link = {
          enable  = false
          fqdn    = "" # Set the fully-qualified domain name (FQDN) of your on-premises VPN gateway device
          address = "" # or set the device public IP address. Do NOT set both configuration parameters.
        }
        bgp = {
          enable = false
          asn    = 0
          peering = {
            address = ""
          }
        }
      }
      pointToSite = {
        enable = true
        client = {
          addressSpace = [
            "10.30.0.0/24"
          ]
        }
      }
    },
    {
      enable     = false
      name       = "uswest"
      hubName    = "USWest"
      scaleUnits = 1
      siteToSite = {
        enable = false
        addressSpace = [
          "10.21.0.0/24"
        ]
        link = {
          enable  = false
          fqdn    = "" # Set the fully-qualified domain name (FQDN) of your on-premises VPN gateway device
          address = "" # or set the device public IP address. Do NOT set both configuration parameters.
        }
        bgp = {
          enable = false
          asn    = 0
          peering = {
            address = ""
          }
        }
      }
      pointToSite = {
        enable = false
        client = {
          addressSpace = [
            "10.31.0.0/24"
          ]
        }
      }
    },
    {
      enable     = false
      name       = "useast"
      hubName    = "USEast"
      scaleUnits = 1
      siteToSite = {
        enable = false
        addressSpace = [
          "10.22.0.0/24"
        ]
        link = {
          enable  = false
          fqdn    = "" # Set the fully-qualified domain name (FQDN) of your on-premises VPN gateway device
          address = "" # or set the device public IP address. Do NOT set both configuration parameters.
        }
        bgp = {
          enable = false
          asn    = 0
          peering = {
            address = ""
          }
        }
      }
      pointToSite = {
        enable = false
        client = {
          addressSpace = [
            "10.32.0.0/24"
          ]
        }
      }
    }
  ]
}

############################################################################
# Private DNS (https://learn.microsoft.com/azure/dns/private-dns-overview) #
############################################################################

privateDNS = {
  zoneName = "azure.hpc"
  autoRegistration = {
    enable = true
  }
}

##################################################################
# Firewall (https://learn.microsoft.com/azure/firewall/overview) #
##################################################################

firewall = {
  enable = false
  name   = "hpcai"
  tier   = "Standard"
}

########################################################################
# Bastion (https://learn.microsoft.com/azure/bastion/bastion-overview) #
########################################################################

bastion = {
  enable              = true
  type                = "Standard"
  scaleUnits          = 2
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
  name   = "Gateway"
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
