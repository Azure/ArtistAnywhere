resourceGroupName = "ArtistAnywhere.Cache" # Alphanumeric, underscores, hyphens, periods and parenthesis are allowed

#######################################################################################################
# Hammerspace (https://azuremarketplace.microsoft.com/marketplace/apps/hammerspace.hammerspace_4_6_5) #
#######################################################################################################

hammerspace = {
  enable     = false
  namePrefix = "xstudio-cache"
  domainName = ""
  metadata = {
    machine = {
      namePrefix = "-anvil"
      size       = "Standard_E4as_v4"
      count      = 1 # Set to 2 (or more) to enable high availability
    }
    adminLogin = {
      userName     = "xadmin"
      userPassword = "P@ssword1234"
      sshPublicKey = "" # "ssh-rsa ..."
      passwordAuth = {
        disable = false
      }
    }
    network = {
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
      }
    }
    osDisk = {
      storageType = "Premium_LRS"
      cachingType = "ReadOnly"
      sizeGB      = 128
    }
    dataDisk = {
      storageType = "Premium_LRS"
      cachingType = "None"
      sizeGB      = 256
    }
  }
  data = {
    machine = {
      namePrefix = "-dsx"
      size       = "Standard_F2s_v2"
      count      = 2
    }
    adminLogin = {
      userName     = "xadmin"
      userPassword = "P@ssword1234"
      sshPublicKey = "" # "ssh-rsa ..."
      passwordAuth = {
        disable = false
      }
    }
    network = {
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
      }
    }
    osDisk = {
      storageType = "Premium_LRS"
      cachingType = "ReadOnly"
      sizeGB      = 128
    }
    dataDisk = {
      storageType = "Premium_LRS"
      cachingType = "None"
      enableRaid0 = false
      sizeGB      = 256
      count       = 2
    }
  }
}

#############################################################
# Arcitecta Mediaflux (https://www.arcitecta.com/mediaflux) #
#############################################################

mediaflux = {
  enable = false
  name   = "xstudio-cache"
  node = {
    size  = "Standard_E32s_v3"
    count = 3
    image = {
      resourceGroupName = "ArtistAnywhere.Image"
      galleryName       = "xstudio"
      definitionName    = "Linux"
      versionId         = "0.0.0"
      plan = {
        publisher = ""
        product   = ""
        name      = ""
      }
    }
    osDisk = {
      storageType = "Premium_LRS"
      cachingType = "ReadOnly"
      sizeGB      = 0
    }
    dataDisk = {
      size = 1024 # Set to either 1024 GB (1 TB) or 4096 GB (4 TB) nodes
    }
    adminLogin = {
      userName     = "xadmin"
      userPassword = "P@ssword1234"
    }
  }
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
hpcCache = {
  enable     = false
  name       = "xstudio-cache"
  throughput = "Standard_L4_5G"
  size       = 21623
  mtuSize    = 1500
  ntpHost    = ""
  dns = {
    ipAddresses = [ # Maximum of 3 IP addresses
    ]
    searchDomain = ""
  }
  encryption = {
    enable    = false
    rotateKey = false
  }
}

#################################################################################
# Avere vFXT (https://learn.microsoft.com/azure/avere-vfxt/avere-vfxt-overview) #
#################################################################################

vfxtCache = {
  enable = false
  name   = "xstudio-cache"
  cluster = {
    nodeSize      = 1024 # Set to either 1024 GB (1 TB) or 4096 GB (4 TB) nodes
    nodeCount     = 3    # Set to a minimum of 3 nodes up to a maximum of 12 nodes
    adminUsername = "xadmin"
    adminPassword = "P@ssword1234"
    sshPublicKey  = ""
    localTimezone = "UTC"
    enableDevMode = false
    imageId = {
      controller = ""
      node       = ""
    }
  }
  activeDirectory = {
    enable            = false
    domainName        = ""
    domainNameNetBIOS = ""
    domainControllers = "" # 1-3 space-separated IP addresses
    domainUsername    = ""
    domainPassword    = ""
  }
  support = {                    # https://privacy.microsoft.com/privacystatement
    companyName      = ""        # https://github.com/Azure/Avere/tree/main/src/terraform/providers/terraform-provider-avere#support_uploads_company_name
    enableLogUpload  = true      # https://github.com/Azure/Avere/tree/main/src/terraform/providers/terraform-provider-avere#enable_support_uploads
    enableProactive  = "Support" # https://github.com/Azure/Avere/tree/main/src/terraform/providers/terraform-provider-avere#enable_secure_proactive_support
    rollingTraceFlag = "0xe4001" # https://github.com/Azure/Avere/tree/main/src/terraform/providers/terraform-provider-avere#rolling_trace_flag
  }
}

############################################################################
# Private DNS (https://learn.microsoft.com/azure/dns/private-dns-overview) #
############################################################################

dnsRecord = {
  ttlSeconds = 300
}

#######################################################################################
# Storage Targets (https://learn.microsoft.com/azure/hpc-cache/hpc-cache-add-storage) #
#######################################################################################

storageTargets = [
  {
    enable            = false
    name              = "Content"
    clientPath        = "/content"
    usageModel        = "READ_ONLY" # https://learn.microsoft.com/azure/hpc-cache/cache-usage-models
    hostName          = "xstudio2"
    containerName     = "content"
    resourceGroupName = "ArtistAnywhere.Storage"
    fileIntervals = {
      verificationSeconds = 30
      writeBackSeconds    = null
    }
    vfxtJunctions = [
      {
        storageExport = ""
        storagePath   = ""
        clientPath    = ""
      }
    ]
  }
]

##################################################################
# Resource dependency configuration for pre-existing deployments #
##################################################################

existingNetwork = {
  enable            = false
  name              = ""
  subnetName        = ""
  regionName        = ""
  resourceGroupName = ""
  privateDns = {
    zoneName          = ""
    resourceGroupName = ""
  }
}
