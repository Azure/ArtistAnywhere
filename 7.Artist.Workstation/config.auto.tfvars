resourceGroupName = "ArtistAnywhere.Workstation" # Alphanumeric, underscores, hyphens, periods and parenthesis are allowed

#########################################################################
# Virtual Machines (https://learn.microsoft.com/azure/virtual-machines) #
#########################################################################

virtualMachines = [
  {
    enable = false
    name   = "LnxArtistN"
    size   = "Standard_NV36ads_A10_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
    count  = 1
    image = {
      resourceGroupName = "ArtistAnywhere.Image"
      galleryName       = "xstudio"
      definitionName    = "Linux"
      versionId         = "3.0.0"
      plan = {
        publisher = ""
        product   = ""
        name      = ""
      }
    }
    network = {
      subnetName = "Workstation"
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
      }
      locationEdge = {
        enable = false
      }
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
          pcoipLicenseKey = ""
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
    name   = "LnxArtistA"
    size   = "Standard_NG32ads_V620_v1" # https://learn.microsoft.com/azure/virtual-machines/sizes
    count  = 1
    image = {
      resourceGroupName = "ArtistAnywhere.Image"
      galleryName       = "xstudio"
      definitionName    = "Linux"
      versionId         = "3.1.0"
      plan = {
        publisher = ""
        product   = ""
        name      = ""
      }
    }
    network = {
      subnetName = "Workstation"
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
      }
      locationEdge = {
        enable = false
      }
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
          pcoipLicenseKey = ""
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
    name   = "WinArtistN"
    size   = "Standard_NV36ads_A10_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
    count  = 1
    image = {
      resourceGroupName = "ArtistAnywhere.Image"
      galleryName       = "xstudio"
      definitionName    = "WinArtist"
      versionId         = "3.0.0"
      plan = {
        publisher = ""
        product   = ""
        name      = ""
      }
    }
    network = {
      subnetName = "Workstation"
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
      }
      locationEdge = {
        enable = false
      }
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
          pcoipLicenseKey = ""
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
    name   = "WinArtistA"
    size   = "Standard_NG32ads_V620_v1" # https://learn.microsoft.com/azure/virtual-machines/sizes
    count  = 1
    image = {
      resourceGroupName = "ArtistAnywhere.Image"
      galleryName       = "xstudio"
      definitionName    = "WinArtist"
      versionId         = "3.1.0"
      plan = {
        publisher = ""
        product   = ""
        name      = ""
      }
    }
    network = {
      subnetName = "Workstation"
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
      }
      locationEdge = {
        enable = false
      }
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
          pcoipLicenseKey = ""
        }
      }
      monitor = {
        enable = false
        name   = "Monitor"
      }
    }
  }
]

##################################################################
# Resource dependency configuration for pre-existing deployments #
##################################################################

activeDirectory = {
  enable           = false
  domainName       = "artist.studio"
  domainServerName = "WinScheduler"
  orgUnitPath      = ""
  adminUsername    = ""
  adminPassword    = ""
}

existingNetwork = {
  enable            = false
  name              = ""
  subnetName        = ""
  resourceGroupName = ""
}
