resourceGroupName = "ArtistAnywhere.Cache" # Alphanumeric, underscores, hyphens, periods and parenthesis are allowed

##################################################################
# Boost (https://learn.microsoft.com/azure/azure-boost/overview) #
##################################################################

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
        placement = "CacheDisk"
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
              source      = "storage-netapp.azure.studio:/data"
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

virtualNetwork = {
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
