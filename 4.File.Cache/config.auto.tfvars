resourceGroupName = "ArtistAnywhere.Cache" # Alphanumeric, underscores, hyphens, periods and parenthesis are allowed

######################################################################################################
# Hammerspace (https://azuremarketplace.microsoft.com/marketplace/apps/hammerspace.hammerspace-byol) #
######################################################################################################

hsCache = {
  enable     = false
  version    = "24.06.19"
  namePrefix = "xstudio"
  domainName = "azure.studio"
  activeDirectory = {
    enable   = false
    servers  = "WinJobScheduler"
    orgUnit  = ""
    username = ""
    password = ""
  }
  metadata = { # Anvil
    machine = {
      namePrefix = "-anvil"
      size       = "Standard_E4as_v5"
      count      = 2
      adminLogin = {
        userName     = ""
        userPassword = ""
        sshKeyPublic = ""
        passwordAuth = {
          disable = false
        }
      }
      osDisk = {
        storageType = "Premium_LRS"
        cachingType = "ReadWrite"
        sizeGB      = 128
      }
      dataDisk = {
        storageType = "Premium_LRS"
        cachingType = "None"
        sizeGB      = 256
      }
    }
    network = {
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
      }
    }
  }
  data = { # DSX
    machine = {
      namePrefix = "-dsx"
      size       = "Standard_E32as_v5"
      count      = 3
      adminLogin = {
        userName     = ""
        userPassword = ""
        sshKeyPublic = ""
        passwordAuth = {
          disable = false
        }
      }
      osDisk = {
        storageType = "Premium_LRS"
        cachingType = "ReadWrite"
        sizeGB      = 128
      }
      dataDisk = {
        storageType = "Premium_LRS"
        cachingType = "None"
        sizeGB      = 256
        count       = 3
        raid0 = {
          enable = false
        }
      }
    }
    network = {
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
      }
    }
  }
  proximityPlacementGroup = { # https://learn.microsoft.com/azure/virtual-machines/co-location
    enable = false
  }
  privateDnsTier = {
    metadata = false
  }
  shares = [
    {
      enable = true
      name   = "volume1"
      path   = "/volume1"
      size   = 0
      export = "*,ro,no-root-squash"
    },
    {
      enable = true
      name   = "volume2"
      path   = "/volume2"
      size   = 0
      export = "*,ro,no-root-squash"
    }
  ]
  storageTargets = [
    {
      enable = true
      node = {
        name = "anf-node1"
        type = "OTHER"
        ip   = "10.1.193.4"
      }
      volume = {
        name      = "anf-volume1"
        type      = "READ_ONLY"
        path      = "/volume1"
        shareName = "volume1"
      }
    },
    {
      enable = true
      node = {
        name = "anf-node2"
        type = "OTHER"
        ip   = "10.1.193.5"
      }
      volume = {
        name      = "anf-volume2"
        type      = "READ_ONLY"
        path      = "/volume2"
        shareName = "volume2"
      }
    }
  ]
  volumeGroups = [
    {
      enable = true
      name   = "anf"
      volumeNames = [
        "anf-volume1",
        "anf-volume2"
      ]
    }
  ]
}

##############################################################################
# HPC Cache (https://learn.microsoft.com/azure/hpc-cache/hpc-cache-overview) #
##############################################################################

# HPC Cache throughput / size (GB) options
#   Standard_L4_5G - 21623                Read Only
#     Standard_L9G - 43246                Read Only
#    Standard_L16G - 86491                Read Only
#      Standard_2G - 3072, 6144, 12288    Read Write
#      Standard_4G - 6144, 12288, 24576   Read Write
#      Standard_8G - 12288, 24576, 49152  Read Write
# hpcCache = {
#   enable     = false
#   name       = "xstudio"
#   throughput = "Standard_L4_5G"
#   size       = 21623
#   mtuSize    = 1500
#   ntpHost    = ""
#   dns = {
#     ipAddresses = [ # Maximum of 3 IP addresses
#     ]
#     searchDomain = ""
#   }
# }

#################################################################################
# Avere vFXT (https://learn.microsoft.com/azure/avere-vfxt/avere-vfxt-overview) #
#################################################################################

# vfxtCache = {
#   enable = false
#   name   = "xstudio"
#   cluster = {
#     nodeSize      = 1024 # Set to either 1024 GB (1 TB) or 4096 GB (4 TB) nodes
#     nodeCount     = 3    # Set to a minimum of 3 nodes up to a maximum of 12 nodes
#     adminUsername = ""
#     adminPassword = ""
#     sshKeyPublic  = ""
#     localTimezone = "UTC"
#     enableDevMode = false
#     imageId = {
#       controller = ""
#       node       = ""
#     }
#   }
#   activeDirectory = {
#     enable            = false
#     domainName        = ""
#     domainNameNetBIOS = ""
#     domainControllers = "" # 1-3 space-separated IP addresses
#     domainUsername    = ""
#     domainPassword    = ""
#   }
#   support = {                    # https://privacy.microsoft.com/privacystatement
#     companyName      = ""        # https://github.com/Azure/Avere/tree/main/src/terraform/providers/terraform-provider-avere#support_uploads_company_name
#     enableLogUpload  = true      # https://github.com/Azure/Avere/tree/main/src/terraform/providers/terraform-provider-avere#enable_support_uploads
#     enableProactive  = "Support" # https://github.com/Azure/Avere/tree/main/src/terraform/providers/terraform-provider-avere#enable_secure_proactive_support
#     rollingTraceFlag = "0xe4001" # https://github.com/Azure/Avere/tree/main/src/terraform/providers/terraform-provider-avere#rolling_trace_flag
#   }
# }

############################################################################
# Private DNS (https://learn.microsoft.com/azure/dns/private-dns-overview) #
############################################################################

dnsRecord = {
  name       = "cache"
  ttlSeconds = 300
}

#######################################################################################
# Storage Targets (https://learn.microsoft.com/azure/hpc-cache/hpc-cache-add-storage) #
#######################################################################################

# storageTargets = [
#   {
#     enable            = false
#     name              = "Storage"
#     clientPath        = "/storage"
#     usageModel        = "READ_ONLY" # https://learn.microsoft.com/azure/hpc-cache/cache-usage-models
#     hostName          = "xstudio1"
#     containerName     = "storage"
#     resourceGroupName = "ArtistAnywhere.Storage"
#     fileIntervals = {
#       verificationSeconds = 30
#       writeBackSeconds    = null
#     }
#     vfxtJunctions = [
#       {
#         storageExport = ""
#         storagePath   = ""
#         clientPath    = ""
#       }
#     ]
#   }
# ]

##################################################
# Pre-Existing Resource Dependency Configuration #
##################################################

existingNetwork = {
  enable            = false
  name              = ""
  subnetName        = ""
  subnetNameHA      = ""
  regionName        = ""
  resourceGroupName = ""
  privateDns = {
    zoneName          = ""
    resourceGroupName = ""
  }
}
