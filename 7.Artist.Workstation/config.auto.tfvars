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
      versionId         = "3.0.0"
      galleryName       = "xstudio"
      definitionName    = "Linux"
      resourceGroupName = "ArtistAnywhere.Image"
      plan = {
        publisher = ""
        product   = ""
        name      = ""
      }
    }
    osDisk = {
      type        = "Linux"
      storageType = "Premium_LRS"
      cachingMode = "ReadWrite"
      sizeGB      = 0
      hibernation = {
        enable = true
      }
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
        name     = "Custom"
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
      versionId         = "3.1.0"
      galleryName       = "xstudio"
      definitionName    = "Linux"
      resourceGroupName = "ArtistAnywhere.Image"
      plan = {
        publisher = ""
        product   = ""
        name      = ""
      }
    }
    osDisk = {
      type        = "Linux"
      storageType = "Premium_LRS"
      cachingMode = "ReadWrite"
      sizeGB      = 0
      hibernation = {
        enable = true
      }
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
        name     = "Custom"
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
      versionId         = "3.0.0"
      galleryName       = "xstudio"
      definitionName    = "WinArtist"
      resourceGroupName = "ArtistAnywhere.Image"
      plan = {
        publisher = ""
        product   = ""
        name      = ""
      }
    }
    osDisk = {
      type        = "Windows"
      storageType = "Premium_LRS"
      cachingMode = "ReadWrite"
      sizeGB      = 0
      hibernation = {
        enable = true
      }
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
        name     = "Custom"
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
      versionId         = "3.1.0"
      galleryName       = "xstudio"
      definitionName    = "WinArtist"
      resourceGroupName = "ArtistAnywhere.Image"
      plan = {
        publisher = ""
        product   = ""
        name      = ""
      }
    }
    osDisk = {
      type        = "Windows"
      storageType = "Premium_LRS"
      cachingMode = "ReadWrite"
      sizeGB      = 0
      hibernation = {
        enable = true
      }
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
        name     = "Custom"
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
