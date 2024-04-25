resourceGroupName = "ArtistAnywhere.Scheduler" # Alphanumeric, underscores, hyphens, periods and parenthesis are allowed

#########################################################################
# Virtual Machines (https://learn.microsoft.com/azure/virtual-machines) #
#########################################################################

virtualMachines = [
  {
    enable = false
    name   = "LnxScheduler"
    size   = "Standard_E8s_v4" # https://learn.microsoft.com/azure/virtual-machines/sizes
    image = {
      resourceGroupName = "ArtistAnywhere.Image"
      galleryName       = "xstudio"
      definitionName    = "Linux"
      versionId         = "1.0.0"
      plan = {
        publisher = ""
        product   = ""
        name      = ""
      }
    }
    network = {
      subnetName = "Farm"
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
      }
      locationEdge = {
        enable = false
      }
      staticIpAddress = ""
    }
    adminLogin = {
      userName     = "xadmin"
      userPassword = "P@ssword1234"
      sshPublicKey = "" # "ssh-rsa ..."
      passwordAuth = {
        disable = false
      }
    }
    operatingSystem = {
      type = "Linux"
      disk = {
        storageType = "Premium_LRS"
        cachingType = "ReadOnly"
        sizeGB      = 0
      }
    }
    extension = {
      custom = {
        enable   = true
        name     = "Initialize"
        fileName = "initialize.sh"
        parameters = {
          autoScale = {
            enable = false
          }
        }
      }
      monitor = {
        enable = false
        name   = "Monitor"
      }
    }
  },
  {
    enable = false
    name   = "WinScheduler"
    size   = "Standard_E8s_v4" # https://learn.microsoft.com/azure/virtual-machines/sizes
    image = {
      resourceGroupName = "ArtistAnywhere.Image"
      galleryName       = "xstudio"
      definitionName    = "WinServer"
      versionId         = "1.0.0"
      plan = {
        publisher = ""
        product   = ""
        name      = ""
      }
    }
    network = {
      subnetName = "Farm"
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
      }
      locationEdge = {
        enable = false
      }
      staticIpAddress = "10.0.127.0"
    }
    adminLogin = {
      userName     = "xadmin"
      userPassword = "P@ssword1234"
      sshPublicKey = "" # "ssh-rsa ..."
      passwordAuth = {
        disable = false
      }
    }
    operatingSystem = {
      type = "Windows"
      disk = {
        storageType = "Premium_LRS"
        cachingType = "ReadOnly"
        sizeGB      = 0
      }
    }
    extension = {
      custom = {
        enable   = true
        name     = "Initialize"
        fileName = "initialize.ps1"
        parameters = {
          autoScale = {
            enable = false
          }
        }
      }
      monitor = {
        enable = false
        name   = "Monitor"
      }
    }
  }
]

############################################################################
# Private DNS (https://learn.microsoft.com/azure/dns/private-dns-overview) #
############################################################################

dnsRecord = {
  name        = "scheduler"
  ttlSeconds  = 300
}

###############################################################################################################
# Active Directory (https://learn.microsoft.comtroubleshoot/windows-server/identity/active-directory-overview #
###############################################################################################################

activeDirectory = {
  enable     = true
  domainName = "artist.studio"
}

##################################################################
# Resource dependency configuration for pre-existing deployments #
##################################################################

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
