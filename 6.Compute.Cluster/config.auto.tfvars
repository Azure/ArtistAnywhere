resourceGroupName = "ArtistAnywhere.Compute" # Alphanumeric, underscores, hyphens, periods and parenthesis are allowed

######################################################################################################
# Virtual Machine Scale Sets (https://learn.microsoft.com/azure/virtual-machine-scale-sets/overview) #
######################################################################################################

virtualMachineScaleSets = [
  {
    enable = false
    name   = "LnxClusterC"
    machine = {
      namePrefix = ""
      size       = "Standard_HX176rs"
      count      = 3
      image = {
        versionId         = "2.0.0"
        galleryName       = "xstudio"
        definitionName    = "Linux"
        resourceGroupName = "ArtistAnywhere.Image"
      }
    }
    network = {
      subnetName = "Compute"
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
      }
      locationExtended = {
        enable = false
      }
    }
    osDisk = {
      type        = "Linux"
      storageType = "Premium_LRS"
      cachingMode = "ReadOnly"
      sizeGB      = 0
      ephemeral = { # https://learn.microsoft.com/azure/virtual-machines/ephemeral-os-disks
        enable    = true
        placement = "ResourceDisk"
      }
    }
    spot = {
      enable         = true     # https://learn.microsoft.com/azure/virtual-machine-scale-sets/use-spot
      evictionPolicy = "Delete" # https://learn.microsoft.com/azure/virtual-machine-scale-sets/use-spot#eviction-policy
      tryRestore = {            # https://learn.microsoft.com/azure/virtual-machine-scale-sets/use-spot#try--restore
        enable  = false
        timeout = "PT1H"
      }
    }
    extension = {
      custom = {
        enable   = true
        name     = "Custom"
        fileName = "initialize.sh"
        parameters = {
          terminateNotification = { # https://learn.microsoft.com/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-terminate-notification
            enable       = false
            delayTimeout = "PT5M"
          }
        }
      }
      health = {
        enable      = true
        name        = "Health"
        protocol    = "tcp"
        port        = 111
        requestPath = ""
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
    availabilityZones = {
      enable = false
      evenDistribution = {
        enable = true
      }
    }
    flexMode = { # https://learn.microsoft.com/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-orchestration-modes
      enable = false
    }
  },
  {
    enable = false
    name   = "LnxClusterGN"
    machine = {
      namePrefix = ""
      size       = "Standard_NC80ads_H100_v5"
      count      = 3
      image = {
        versionId         = "2.1.0"
        galleryName       = "xstudio"
        definitionName    = "Linux"
        resourceGroupName = "ArtistAnywhere.Image"
      }
    }
    network = {
      subnetName = "Compute"
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
      }
      locationExtended = {
        enable = false
      }
    }
    osDisk = {
      type        = "Linux"
      storageType = "Premium_LRS"
      cachingMode = "ReadOnly"
      sizeGB      = 0
      ephemeral = { # https://learn.microsoft.com/azure/virtual-machines/ephemeral-os-disks
        enable    = true
        placement = "ResourceDisk"
      }
    }
    spot = {
      enable         = false    # https://learn.microsoft.com/azure/virtual-machine-scale-sets/use-spot
      evictionPolicy = "Delete" # https://learn.microsoft.com/azure/virtual-machine-scale-sets/use-spot#eviction-policy
      tryRestore = {            # https://learn.microsoft.com/azure/virtual-machine-scale-sets/use-spot#try--restore
        enable  = false
        timeout = "PT1H"
      }
    }
    extension = {
      custom = {
        enable   = true
        name     = "Custom"
        fileName = "initialize.sh"
        parameters = {
          terminateNotification = { # https://learn.microsoft.com/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-terminate-notification
            enable       = false
            delayTimeout = "PT5M"
          }
        }
      }
      health = {
        enable      = true
        name        = "Health"
        protocol    = "tcp"
        port        = 111
        requestPath = ""
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
    availabilityZones = {
      enable = false
      evenDistribution = {
        enable = true
      }
    }
    flexMode = { # https://learn.microsoft.com/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-orchestration-modes
      enable = false
    }
  },
  {
    enable = false
    name   = "LnxClusterGA"
    machine = {
      namePrefix = ""
      size       = "Standard_NV28adms_V710_v5"
      count      = 3
      image = {
        versionId         = "2.2.0"
        galleryName       = "xstudio"
        definitionName    = "Linux"
        resourceGroupName = "ArtistAnywhere.Image"
      }
    }
    network = {
      subnetName = "Compute"
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
      }
      locationExtended = {
        enable = false
      }
    }
    osDisk = {
      type        = "Linux"
      storageType = "Premium_LRS"
      cachingMode = "ReadOnly"
      sizeGB      = 0
      ephemeral = { # https://learn.microsoft.com/azure/virtual-machines/ephemeral-os-disks
        enable    = true
        placement = "ResourceDisk"
      }
    }
    spot = {
      enable         = false    # https://learn.microsoft.com/azure/virtual-machine-scale-sets/use-spot
      evictionPolicy = "Delete" # https://learn.microsoft.com/azure/virtual-machine-scale-sets/use-spot#eviction-policy
      tryRestore = {            # https://learn.microsoft.com/azure/virtual-machine-scale-sets/use-spot#try--restore
        enable  = false
        timeout = "PT1H"
      }
    }
    extension = {
      custom = {
        enable   = true
        name     = "Custom"
        fileName = "initialize.sh"
        parameters = {
          terminateNotification = { # https://learn.microsoft.com/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-terminate-notification
            enable       = false
            delayTimeout = "PT5M"
          }
        }
      }
      health = {
        enable      = true
        name        = "Health"
        protocol    = "tcp"
        port        = 111
        requestPath = ""
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
    availabilityZones = {
      enable = false
      evenDistribution = {
        enable = true
      }
    }
    flexMode = { # https://learn.microsoft.com/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-orchestration-modes
      enable = false
    }
  },
  {
    enable = false
    name   = "WinClusterC"
    machine = {
      namePrefix = ""
      size       = "Standard_HX176rs"
      count      = 3
      image = {
        versionId         = "2.0.0"
        galleryName       = "xstudio"
        definitionName    = "WinCluster"
        resourceGroupName = "ArtistAnywhere.Image"
      }
    }
    network = {
      subnetName = "Compute"
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
      }
      locationExtended = {
        enable = false
      }
    }
    osDisk = {
      type        = "Windows"
      storageType = "Premium_LRS"
      cachingMode = "ReadOnly"
      sizeGB      = 0
      ephemeral = { # https://learn.microsoft.com/azure/virtual-machines/ephemeral-os-disks
        enable    = true
        placement = "ResourceDisk"
      }
    }
    spot = {
      enable         = true     # https://learn.microsoft.com/azure/virtual-machine-scale-sets/use-spot
      evictionPolicy = "Delete" # https://learn.microsoft.com/azure/virtual-machine-scale-sets/use-spot#eviction-policy
      tryRestore = {            # https://learn.microsoft.com/azure/virtual-machine-scale-sets/use-spot#try--restore
        enable  = false
        timeout = "PT1H"
      }
    }
    extension = {
      custom = {
        enable   = true
        name     = "Custom"
        fileName = "initialize.ps1"
        parameters = {
          terminateNotification = { # https://learn.microsoft.com/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-terminate-notification
            enable       = false
            delayTimeout = "PT5M"
          }
        }
      }
      health = {
        enable      = true
        name        = "Health"
        protocol    = "tcp"
        port        = 445
        requestPath = ""
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
    availabilityZones = {
      enable = false
      evenDistribution = {
        enable = true
      }
    }
    flexMode = { # https://learn.microsoft.com/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-orchestration-modes
      enable = false
    }
  },
  {
    enable = false
    name   = "WinClusterGN"
    machine = {
      namePrefix = ""
      size       = "Standard_NC80ads_H100_v5"
      count      = 3
      image = {
        versionId         = "2.1.0"
        galleryName       = "xstudio"
        definitionName    = "WinCluster"
        resourceGroupName = "ArtistAnywhere.Image"
      }
    }
    network = {
      subnetName = "Compute"
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
      }
      locationExtended = {
        enable = false
      }
    }
    osDisk = {
      type        = "Windows"
      storageType = "Premium_LRS"
      cachingMode = "ReadOnly"
      sizeGB      = 0
      ephemeral = { # https://learn.microsoft.com/azure/virtual-machines/ephemeral-os-disks
        enable    = true
        placement = "ResourceDisk"
      }
    }
    spot = {
      enable         = false    # https://learn.microsoft.com/azure/virtual-machine-scale-sets/use-spot
      evictionPolicy = "Delete" # https://learn.microsoft.com/azure/virtual-machine-scale-sets/use-spot#eviction-policy
      tryRestore = {            # https://learn.microsoft.com/azure/virtual-machine-scale-sets/use-spot#try--restore
        enable  = false
        timeout = "PT1H"
      }
    }
    extension = {
      custom = {
        enable   = true
        name     = "Custom"
        fileName = "initialize.ps1"
        parameters = {
          terminateNotification = { # https://learn.microsoft.com/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-terminate-notification
            enable       = false
            delayTimeout = "PT5M"
          }
        }
      }
      health = {
        enable      = true
        name        = "Health"
        protocol    = "tcp"
        port        = 445
        requestPath = ""
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
    availabilityZones = {
      enable = false
      evenDistribution = {
        enable = true
      }
    }
    flexMode = { # https://learn.microsoft.com/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-orchestration-modes
      enable = false
    }
  },
  {
    enable = false
    name   = "WinClusterGA"
    machine = {
      namePrefix = ""
      size       = "Standard_NV28adms_V710_v5"
      count      = 3
      image = {
        versionId         = "2.1.0"
        galleryName       = "xstudio"
        definitionName    = "WinCluster"
        resourceGroupName = "ArtistAnywhere.Image"
      }
    }
    network = {
      subnetName = "Compute"
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
      }
      locationExtended = {
        enable = false
      }
    }
    osDisk = {
      type        = "Windows"
      storageType = "Premium_LRS"
      cachingMode = "ReadOnly"
      sizeGB      = 0
      ephemeral = { # https://learn.microsoft.com/azure/virtual-machines/ephemeral-os-disks
        enable    = true
        placement = "ResourceDisk"
      }
    }
    spot = {
      enable         = false    # https://learn.microsoft.com/azure/virtual-machine-scale-sets/use-spot
      evictionPolicy = "Delete" # https://learn.microsoft.com/azure/virtual-machine-scale-sets/use-spot#eviction-policy
      tryRestore = {            # https://learn.microsoft.com/azure/virtual-machine-scale-sets/use-spot#try--restore
        enable  = false
        timeout = "PT1H"
      }
    }
    extension = {
      custom = {
        enable   = true
        name     = "Custom"
        fileName = "initialize.ps1"
        parameters = {
          terminateNotification = { # https://learn.microsoft.com/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-terminate-notification
            enable       = false
            delayTimeout = "PT5M"
          }
        }
      }
      health = {
        enable      = true
        name        = "Health"
        protocol    = "tcp"
        port        = 445
        requestPath = ""
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
    availabilityZones = {
      enable = false
      evenDistribution = {
        enable = true
      }
    }
    flexMode = { # https://learn.microsoft.com/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-orchestration-modes
      enable = false
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
