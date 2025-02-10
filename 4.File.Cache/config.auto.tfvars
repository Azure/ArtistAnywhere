resourceGroupName = "ArtistAnywhere.Cache" # Alphanumeric, underscores, hyphens, periods and parenthesis are allowed

knfsdCache = {
  enable = false
  cluster = {
    name = "xstudio"
    size = 1
    node = {
      name = "cache"
      size = "Standard_L80as_v3" # https://learn.microsoft.com/azure/virtual-machines/sizes
      image = {
        publisher = ""
        product   = ""
        name      = ""
        version   = ""
      }
      osDisk = {
        storageType = "Premium_LRS"
        cachingType = "ReadOnly"
        sizeGB      = 0
        ephemeral = { # https://learn.microsoft.com/azure/virtual-machines/ephemeral-os-disks
          enable    = true
          placement = "ResourceDisk"
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
      extension = {
        custom = {
          enable   = true
          name     = "Custom"
          fileName = "knfsd.sh"
          parameters = {
            storageMounts = [
              {
                enable      = true
                description = "Local NVMe Disks"
                type        = "xfs"
                path        = "/mnt/fscache"
                source      = "/dev/md/fscache"
                options     = "defaults"
              },
              {
                enable      = true
                description = "Remote NFSv3 Storage"
                type        = "nfs"
                path        = "/mnt/storage"
                source      = "storage-data.azure.studio:/data"
                options     = "vers=3,fsc"
              }
            ]
          }
        }
      }
    }
  }
  network = {
    acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
      enable = true
    }
  }
}

###################################################
# Hammerspace (https://www.hammerspace.com/azure) #
###################################################

hammerspace = {
  enable     = false
  version    = "24.06.19"
  namePrefix = "xstudio"
  domainName = "azure.studio"
  metadata = { # Anvil
    machine = {
      namePrefix = "-anvil"
      size       = "Standard_E8as_v5"
      count      = 1
      osDisk = {
        storageType = "Premium_LRS"
        cachingType = "ReadWrite"
        sizeGB      = 128
      }
      dataDisk = {
        storageType = "Premium_LRS"
        cachingType = "None"
        sizeGB      = 1024
      }
      adminLogin = {
        userName     = ""
        userPassword = ""
        sshKeyPublic = ""
        passwordAuth = {
          disable = true
        }
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
      count      = 2
      osDisk = {
        storageType = "Premium_LRS"
        cachingType = "ReadWrite"
        sizeGB      = 128
      }
      dataDisk = {
        storageType = "Premium_LRS"
        cachingType = "None"
        sizeGB      = 1024
        count       = 4
        raid0 = {
          enable = false
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
  storageAccounts = [
    {
      enable    = false
      name      = ""
      accessKey = ""
    }
  ]
  shares = [
    {
      enable = false
      name   = "cache"
      path   = "/cache"
      size   = 0
      export = "*,ro,root-squash,insecure"
    }
  ]
  volumes = [
    {
      enable = false
      name   = "data-cpu"
      type   = "READ_ONLY"
      path   = "/data/cpu"
      node = {
        name    = "node1"
        type    = "OTHER"
        address = "10.1.194.4"
      }
      assimilation = {
        enable = true
        share = {
          name = "cache"
          path = {
            source      = "/"
            destination = "/moana"
          }
        }
      }
    },
    {
      enable = false
      name   = "data-gpu"
      type   = "READ_ONLY"
      path   = "/data/gpu"
      node = {
        name    = "node2"
        type    = "OTHER"
        address = "10.1.194.4"
      }
      assimilation = {
        enable = true
        share = {
          name = "cache"
          path = {
            source      = "/"
            destination = "/blender"
          }
        }
      }
    }
  ]
  volumeGroups = [
    {
      enable = false
      name   = "cache"
      volumeNames = [
        "data-cpu",
        "data-gpu"
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
    imageUrn = {
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
  name       = "cache"
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

########################
# Brownfield Resources #
########################

activeDirectory = {
  enable       = false
  domainName   = "azure.studio"
  servers      = "WinADDC"
  userName     = ""
  userPassword = ""
}

existingNetwork = {
  enable            = false
  name              = ""
  subnetName        = ""
  resourceGroupName = ""
  privateDns = {
    zoneName          = ""
    resourceGroupName = ""
  }
}
