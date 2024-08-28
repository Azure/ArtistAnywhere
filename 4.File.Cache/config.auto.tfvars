resourceGroupName = "ArtistAnywhere.Cache" # Alphanumeric, underscores, hyphens, periods and parenthesis are allowed

#######################################################################################################
# Weka (https://azuremarketplace.microsoft.com/marketplace/apps/weka1652213882079.weka_data_platform) #
#######################################################################################################

weka = {
  enable   = false
  version  = "4.3.4"
  apiToken = ""
  name = {
    resource = "xstudio"
    display  = "Azure Artist Anywhere"
  }
  machine = {
    size  = "Standard_L8s_v3"
    count = 6
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
  }
  adminLogin = {
    userName     = ""
    userPassword = ""
    sshKeyPublic = ""
    passwordAuth = {
      disable = true
    }
  }
  network = {
    acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
      enable = true
    }
    dnsRecord = {
      name    = "storage"
      ttlSeconds = 300
    }
  }
  terminateNotification = {
    enable       = true
    delayTimeout = "PT15M"
  }
  objectTier = {
    percent = 80
    storage = {
      accountName   = ""
      accountKey    = ""
      containerName = "weka"
    }
  }
  fileSystem = {
    name         = "default"
    groupName    = "default"
    autoScale    = false
    authRequired = false
    loadFiles    = false
  }
  osDisk = {
    storageType = "Standard_LRS"
    cachingType = "ReadOnly"
    sizeGB      = 0
  }
  dataDisk = {
    storageType = "Standard_LRS"
    cachingType = "None"
    sizeGB      = 512
  }
  dataProtection = {
    stripeWidth = 3
    parityLevel = 2
    hotSpare    = 1
  }
  healthExtension = {
    protocol    = "http"
    port        = 14000
    requestPath = "/ui"
  }
  license = {
    key = ""
    payGo = {
      planId    = ""
      secretKey = ""
    }
  }
  supportUrl = ""
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
  name       = "xstudio"
  throughput = "Standard_L4_5G"
  size       = 21623
  mtuSize    = 1500
  ntpHost    = ""
  dns = {
    ipAddresses = [ # Maximum of 3 IP addresses
    ]
    searchDomain = ""
  }
}

#################################################################################
# Avere vFXT (https://learn.microsoft.com/azure/avere-vfxt/avere-vfxt-overview) #
#################################################################################

vfxtCache = {
  enable = false
  name   = "xstudio"
  cluster = {
    nodeSize      = 1024 # Set to either 1024 GB (1 TB) or 4096 GB (4 TB) nodes
    nodeCount     = 3    # Set to a minimum of 3 nodes up to a maximum of 12 nodes
    adminUsername = ""
    adminPassword = ""
    sshKeyPublic  = ""
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
    name              = "Storage"
    clientPath        = "/storage"
    usageModel        = "READ_ONLY" # https://learn.microsoft.com/azure/hpc-cache/cache-usage-models
    hostName          = "xstudio1"
    containerName     = "storage"
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

##################################################
# Pre-Existing Resource Dependency Configuration #
##################################################

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
