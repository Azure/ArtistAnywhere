resourceGroupName = "AAA.Workstation"

#########################################################################
# Virtual Machines (https://learn.microsoft.com/azure/virtual-machines) #
#########################################################################

virtualMachines = [
  {
    enable = false
    name   = "VDIUserXLGN"
    size   = "Standard_NV72ads_A10_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
    count  = 1
    image = {
      versionId         = "3.0.0"
      galleryName       = "hpcai"
      definitionName    = "LnxX"
      resourceGroupName = "AAA.Image.Gallery"
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
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
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
    }
    monitor = {
      enable = true
      metric = {
        category = "AllMetrics"
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
    name   = "VDIUserXLGA"
    size   = "Standard_NV28adms_V710_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
    count  = 1
    image = {
      versionId         = "3.1.0"
      galleryName       = "hpcai"
      definitionName    = "LnxX"
      resourceGroupName = "AAA.Image.Gallery"
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
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
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
    }
    monitor = {
      enable = true
      metric = {
        category = "AllMetrics"
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
    name   = "VDIUserAL"
    size   = "Standard_E96ps_v6" # https://learn.microsoft.com/azure/virtual-machines/sizes
    count  = 1
    image = {
      versionId         = "3.0.0"
      galleryName       = "hpcai"
      definitionName    = "aLinux"
      resourceGroupName = "AAA.Image.Gallery"
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
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
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
    }
    monitor = {
      enable = true
      metric = {
        category = "AllMetrics"
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
    name   = "VDIUserXWGN"
    size   = "Standard_NV72ads_A10_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
    count  = 1
    image = {
      versionId         = "3.0.0"
      galleryName       = "hpcai"
      definitionName    = "WinUser"
      resourceGroupName = "AAA.Image.Gallery"
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
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
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
    }
    monitor = {
      enable = true
      metric = {
        category = "AllMetrics"
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
    name   = "VDIUserXWGA"
    size   = "Standard_NV28adms_V710_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
    count  = 1
    image = {
      versionId         = "3.1.0"
      galleryName       = "hpcai"
      definitionName    = "WinUser"
      resourceGroupName = "AAA.Image.Gallery"
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
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
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
    }
    monitor = {
      enable = true
      metric = {
        category = "AllMetrics"
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
    name   = "VDIUserAW"
    size   = "Standard_E96ps_v6" # https://learn.microsoft.com/azure/virtual-machines/sizes
    count  = 1
    image = {
      versionId         = "3.0.0"
      galleryName       = "hpcai"
      definitionName    = "WinUser"
      resourceGroupName = "AAA.Image.Gallery"
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
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
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
    }
    monitor = {
      enable = true
      metric = {
        category = "AllMetrics"
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
]

########################
# Brownfield Resources #
########################

virtualNetwork = {
  name              = "HPC"
  subnetName        = "VDI"
  edgeZoneName      = "" # "LosAngeles"
  resourceGroupName = "AAA.Network.SouthCentralUS" # "AAA.Network.WestUS.LosAngeles"
}

activeDirectory = {
  enable = false
  domain = {
    name = "azure.hpc"
  }
  machine = {
    name = "WinAD"
    adminLogin = {
      userName     = ""
      userPassword = ""
    }
  }
}
