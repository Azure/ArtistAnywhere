resourceGroupName = "AAA.Job.Cluster"

######################################################################################################
# Virtual Machine Scale Sets (https://learn.microsoft.com/azure/virtual-machine-scale-sets/overview) #
######################################################################################################

vmScaleSets = [
  {
    enable = false
    name   = "LnxJobClusterCA"
    machine = {
      namePrefix = ""
      size       = "Standard_HX176rs"
      count      = 3
      image = {
        versionId         = "2.0.0"
        galleryName       = "hpcai"
        definitionName    = "Linux"
        resourceGroupName = "AAA.Image"
      }
      bootDiagnostics = {
        enable = true
      }
    }
    network = {
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
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
        fileName = "cse.sh"
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
    name   = "LnxJobClusterCI"
    machine = {
      namePrefix = ""
      size       = "Standard_FX96ms_v2"
      count      = 3
      image = {
        versionId         = "2.1.0"
        galleryName       = "hpcai"
        definitionName    = "Linux"
        resourceGroupName = "AAA.Image"
      }
      bootDiagnostics = {
        enable = true
      }
    }
    network = {
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
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
        fileName = "cse.sh"
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
    name   = "LnxJobClusterGN"
    machine = {
      namePrefix = ""
      size       = "Standard_NC40ads_H100_v5"
      count      = 3
      image = {
        versionId         = "2.2.0"
        galleryName       = "hpcai"
        definitionName    = "Linux"
        resourceGroupName = "AAA.Image"
      }
      bootDiagnostics = {
        enable = true
      }
    }
    network = {
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
      }
    }
    osDisk = {
      type        = "Linux"
      storageType = "Premium_LRS"
      cachingMode = "ReadOnly"
      sizeGB      = 0
      ephemeral = { # https://learn.microsoft.com/azure/virtual-machines/ephemeral-os-disks
        enable    = true
        placement = "CacheDisk"
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
        fileName = "cse.sh"
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
    name   = "LnxJobClusterGA"
    machine = {
      namePrefix = ""
      size       = "Standard_ND96isr_MI300X_v5"
      count      = 3
      image = {
        versionId         = "2.3.0"
        galleryName       = "hpcai"
        definitionName    = "Linux"
        resourceGroupName = "AAA.Image"
      }
      bootDiagnostics = {
        enable = true
      }
    }
    network = {
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
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
        fileName = "cse.sh"
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
    name   = "WinJobClusterCA"
    machine = {
      namePrefix = ""
      size       = "Standard_HX176rs"
      count      = 3
      image = {
        versionId         = "2.0.0"
        galleryName       = "hpcai"
        definitionName    = "WinJobCluster"
        resourceGroupName = "AAA.Image"
      }
      bootDiagnostics = {
        enable = true
      }
    }
    network = {
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
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
        fileName = "cse.ps1"
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
    name   = "WinJobClusterCI"
    machine = {
      namePrefix = ""
      size       = "Standard_FX96ms_v2"
      count      = 3
      image = {
        versionId         = "2.1.0"
        galleryName       = "hpcai"
        definitionName    = "WinJobCluster"
        resourceGroupName = "AAA.Image"
      }
      bootDiagnostics = {
        enable = true
      }
    }
    network = {
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
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
        fileName = "cse.ps1"
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
    name   = "WinJobClusterGN"
    machine = {
      namePrefix = ""
      size       = "Standard_NC40ads_H100_v5"
      count      = 3
      image = {
        versionId         = "2.2.0"
        galleryName       = "hpcai"
        definitionName    = "WinJobCluster"
        resourceGroupName = "AAA.Image"
      }
      bootDiagnostics = {
        enable = true
      }
    }
    network = {
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
      }
    }
    osDisk = {
      type        = "Windows"
      storageType = "Premium_LRS"
      cachingMode = "ReadOnly"
      sizeGB      = 0
      ephemeral = { # https://learn.microsoft.com/azure/virtual-machines/ephemeral-os-disks
        enable    = true
        placement = "CacheDisk"
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
        fileName = "cse.ps1"
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
    name   = "WinJobClusterGA"
    machine = {
      namePrefix = ""
      size       = "Standard_ND96isr_MI300X_v5"
      count      = 3
      image = {
        versionId         = "2.3.0"
        galleryName       = "hpcai"
        definitionName    = "WinJobCluster"
        resourceGroupName = "AAA.Image"
      }
      bootDiagnostics = {
        enable = true
      }
    }
    network = {
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
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
        fileName = "cse.ps1"
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

virtualNetwork = {
  name              = "HPC"
  subnetName        = "Cluster"
  edgeZoneName      = "" # "LosAngeles"
  resourceGroupName = "AAA.Network.SouthCentralUS" # "AAA.Network.WestUS.LosAngeles"
}

activeDirectory = {
  enable = false
  domain = {
    name = "azure.hpc"
  }
  machine = {
    name = "WinADController"
    adminLogin = {
      userName     = ""
      userPassword = ""
    }
  }
}

containerRegistry = {
  enable            = true
  name              = "hpcai"
  resourceGroupName = "AAA.Image.Registry"
}
