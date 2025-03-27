resourceGroupName = "ArtistAnywhere.Cache" # Alphanumeric, underscores, hyphens, periods and parenthesis are allowed

######################################################################################################
# Hammerspace (https://azuremarketplace.microsoft.com/marketplace/apps/hammerspace.hammerspace-byol) #
######################################################################################################

hsCache = {
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
        cachingMode = "ReadWrite"
        sizeGB      = 128
      }
      dataDisk = {
        storageType = "Premium_LRS"
        cachingMode = "None"
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
        cachingMode = "ReadWrite"
        sizeGB      = 128
      }
      dataDisk = {
        storageType = "Premium_LRS"
        cachingMode = "None"
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

nfsCache = {
  enable = false
  name   = "xcache"
  machine = {
    size   = "Standard_L80s_v3" # https://learn.microsoft.com/azure/virtual-machines/sizes
    count  = 1
    prefix = ""
    image = {
      publisher = ""
      product   = ""
      name      = ""
      version   = ""
    }
    osDisk = {
      storageType = "Premium_LRS"
      cachingMode = "ReadOnly"
      sizeGB      = 0
      ephemeral = { # https://learn.microsoft.com/azure/virtual-machines/ephemeral-os-disks
        enable    = true
        placement = "ResourceDisk"
      }
    }
    dataDisk = {
      enable      = false
      storageType = "UltraSSD_LRS"
      cachingMode = "None"
      sizeGB      = 65536
      count       = 3
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
        fileName = "nfs.sh"
        parameters = {
          storageMounts = [
            {
              enable      = true
              type        = "nfs"
              path        = "/storage"
              source      = "storage.azure.studio:/data"
              options     = "fsc,ro,nconnect=8,vers=3"
              description = "Remote NFSv3 Storage"
            }
          ]
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

############################################################################
# Private DNS (https://learn.microsoft.com/azure/dns/private-dns-overview) #
############################################################################

dnsRecord = {
  name       = "cache"
  ttlSeconds = 300
}

########################
# Brownfield Resources #
########################

existingNetwork = {
  enable            = false
  name              = ""
  subnetName        = ""
  resourceGroupName = ""
  privateDNS = {
    zoneName          = ""
    resourceGroupName = ""
  }
}

activeDirectory = {
  enable = false
  domain = {
    name = "azure.studio"
  }
  machine = {
    name = "WinADController"
    adminLogin = {
      userName     = ""
      userPassword = ""
    }
  }
}
