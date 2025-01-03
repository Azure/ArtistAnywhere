resourceGroupName = "ArtistAnywhere.Workstation" # Alphanumeric, underscores, hyphens, periods and parenthesis are allowed

#########################################################################
# Virtual Machines (https://learn.microsoft.com/azure/virtual-machines) #
#########################################################################

virtualMachines = [
  {
    enable = false
    name   = "LnxArtistGN"
    size   = "Standard_NV72ads_A10_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
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
    osDisk = {
      type        = "Linux"
      storageType = "Premium_LRS"
      cachingType = "ReadWrite"
      sizeGB      = 0
    }
    network = {
      subnetName = "Workstation"
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
      }
      locationExtended = {
        enable = false
      }
    }
    extension = {
      custom = {
        enable   = true
        name     = "Initialize"
        fileName = "initialize.sh"
        parameters = {
          remoteAgentKey = ""
        }
      }
      monitor = {
        enable = false
        name   = "Monitor"
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
  },
  {
    enable = false
    name   = "LnxArtistGA"
    size   = "Standard_NV28adms_V710_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
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
    osDisk = {
      type        = "Linux"
      storageType = "Premium_LRS"
      cachingType = "ReadWrite"
      sizeGB      = 0
    }
    network = {
      subnetName = "Workstation"
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
      }
      locationExtended = {
        enable = false
      }
    }
    extension = {
      custom = {
        enable   = true
        name     = "Initialize"
        fileName = "initialize.sh"
        parameters = {
          remoteAgentKey = ""
        }
      }
      monitor = {
        enable = false
        name   = "Monitor"
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
  },
  {
    enable = false
    name   = "WinArtistGN"
    size   = "Standard_NV72ads_A10_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
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
    osDisk = {
      type        = "Windows"
      storageType = "Premium_LRS"
      cachingType = "ReadWrite"
      sizeGB      = 0
    }
    network = {
      subnetName = "Workstation"
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
      }
      locationExtended = {
        enable = false
      }
    }
    extension = {
      custom = {
        enable   = true
        name     = "Initialize"
        fileName = "initialize.ps1"
        parameters = {
          remoteAgentKey = ""
        }
      }
      monitor = {
        enable = false
        name   = "Monitor"
      }
    }
    adminLogin = {
      userName     = ""
      userPassword = ""
      sshKeyPublic = ""
      passwordAuth = {
        disable = false
      }
    }
  },
  {
    enable = false
    name   = "WinArtistGA"
    size   = "Standard_NV28adms_V710_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
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
    osDisk = {
      type        = "Windows"
      storageType = "Premium_LRS"
      cachingType = "ReadWrite"
      sizeGB      = 0
    }
    network = {
      subnetName = "Workstation"
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
      }
      locationExtended = {
        enable = false
      }
    }
    extension = {
      custom = {
        enable   = true
        name     = "Initialize"
        fileName = "initialize.ps1"
        parameters = {
          remoteAgentKey = ""
        }
      }
      monitor = {
        enable = false
        name   = "Monitor"
      }
    }
    adminLogin = {
      userName     = ""
      userPassword = ""
      sshKeyPublic = ""
      passwordAuth = {
        disable = false
      }
    }
  }
]

########################
# Brownfield Resources #
########################

activeDirectory = {
  enable        = false
  domainName    = "azure.studio"
  serverName    = "WinADDC"
  orgUnitPath   = ""
  adminUsername = ""
  adminPassword = ""
}

existingNetwork = {
  enable            = false
  name              = ""
  subnetName        = ""
  resourceGroupName = ""
}
