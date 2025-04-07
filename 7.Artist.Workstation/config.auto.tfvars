resourceGroupName = "ArtistAnywhere.Workstation" # Alphanumeric, underscores, hyphens, periods and parenthesis are allowed

extendedZone = {
  enable   = false
  name     = "LosAngeles"
  location = "WestUS"
}

#########################################################################
# Virtual Machines (https://learn.microsoft.com/azure/virtual-machines) #
#########################################################################

virtualMachines = [
  {
    enable = false
    name   = "LnxArtistGPU-N"
    size   = "Standard_NV72ads_A10_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
    count  = 1
    image = {
      versionId         = "3.0.0"
      galleryName       = "xstudio"
      definitionName    = "Linux"
      resourceGroupName = "ArtistAnywhere.Image"
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
        fileName = "cse.sh"
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
    name   = "LnxArtistGPU-A"
    size   = "Standard_NV28adms_V710_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
    count  = 1
    image = {
      versionId         = "3.1.0"
      galleryName       = "xstudio"
      definitionName    = "Linux"
      resourceGroupName = "ArtistAnywhere.Image"
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
        fileName = "cse.sh"
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
    name   = "WinArtistGPU-N"
    size   = "Standard_NV72ads_A10_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
    count  = 1
    image = {
      versionId         = "3.0.0"
      galleryName       = "xstudio"
      definitionName    = "WinArtist"
      resourceGroupName = "ArtistAnywhere.Image"
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
        fileName = "cse.ps1"
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
    name   = "WinArtistGPU-A"
    size   = "Standard_NV28adms_V710_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
    count  = 1
    image = {
      versionId         = "3.1.0"
      galleryName       = "xstudio"
      definitionName    = "WinArtist"
      resourceGroupName = "ArtistAnywhere.Image"
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
        fileName = "cse.ps1"
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

virtualNetwork = {
  enable            = false
  name              = ""
  subnetName        = ""
  resourceGroupName = ""
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
