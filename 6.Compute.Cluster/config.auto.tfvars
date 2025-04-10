resourceGroupName = "ArtistAnywhere.Cluster" # Alphanumeric, underscores, hyphens, periods and parenthesis are allowed

extendedZone = {
  enable   = false
  name     = "LosAngeles"
  location = "WestUS"
}

######################################################################################################
# Virtual Machine Scale Sets (https://learn.microsoft.com/azure/virtual-machine-scale-sets/overview) #
######################################################################################################

virtualMachineScaleSets = [
  {
    enable = false
    name   = "LnxClusterCPU"
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
      subnetName = "Cluster"
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
    name   = "LnxClusterGPU-N"
    machine = {
      namePrefix = ""
      size       = "Standard_NC40ads_H100_v5"
      count      = 3
      image = {
        versionId         = "2.1.0"
        galleryName       = "xstudio"
        definitionName    = "Linux"
        resourceGroupName = "ArtistAnywhere.Image"
      }
    }
    network = {
      subnetName = "Cluster"
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
    name   = "LnxClusterGPU-A"
    machine = {
      namePrefix = ""
      size       = "Standard_ND96isr_MI300X_v5"
      count      = 3
      image = {
        versionId         = "2.2.0"
        galleryName       = "xstudio"
        definitionName    = "Linux"
        resourceGroupName = "ArtistAnywhere.Image"
      }
    }
    network = {
      subnetName = "Cluster"
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
    name   = "WinClusterCPU"
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
      subnetName = "Cluster"
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
    name   = "WinClusterGPU-N"
    machine = {
      namePrefix = ""
      size       = "Standard_NC40ads_H100_v5"
      count      = 3
      image = {
        versionId         = "2.1.0"
        galleryName       = "xstudio"
        definitionName    = "WinCluster"
        resourceGroupName = "ArtistAnywhere.Image"
      }
    }
    network = {
      subnetName = "Cluster"
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
    name   = "WinClusterGPU-A"
    machine = {
      namePrefix = ""
      size       = "Standard_ND96isr_MI300X_v5"
      count      = 3
      image = {
        versionId         = "2.1.0"
        galleryName       = "xstudio"
        definitionName    = "WinCluster"
        resourceGroupName = "ArtistAnywhere.Image"
      }
    }
    network = {
      subnetName = "Cluster"
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

##################################################################################
# Compute Fleet (https://learn.microsoft.com/azure/azure-compute-fleet/overview) #
##################################################################################

computeFleets = [
  {
    enable = false
    name   = "LnxClusterCPU"
    machine = {
      namePrefix = ""
      sizes = [
        {
          name = "Standard_HX176rs"
        },
        {
          name = "Standard_HX176-144rs"
        },
        {
          name = "Standard_HX176-96rs"
        }
      ]
      image = {
        versionId         = "2.0.0"
        galleryName       = "xstudio"
        definitionName    = "Linux"
        resourceGroupName = "ArtistAnywhere.Image"
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
      priority = {
        standard = {
          allocationStrategy = "LowestPrice"
          capacityTarget     = 2
          capacityMinimum    = 1
        }
        spot = {
          allocationStrategy = "PriceCapacityOptimized"
          evictionPolicy     = "Delete"
          capacityTarget     = 0
          capacityMinimum    = 0
          capacityMaintain = {
            enable = true
          }
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
        monitor = {
          enable = false
          name   = "Monitor"
        }
      }
      adminLogin = {
        userName     = ""
        userPassword = ""
        sshKeyPublic = ""
      }
    }
    network = {
      subnetName = "Cluster"
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
      }
      locationExtended = {
        enable = false
      }
    }
  },
  {
    enable = false
    name   = "WinClusterCPU"
    machine = {
      namePrefix = ""
      sizes = [
        {
          name = "Standard_HX176rs"
        },
        {
          name = "Standard_HX176-144rs"
        },
        {
          name = "Standard_HX176-96rs"
        }
      ]
      image = {
        versionId         = "2.0.0"
        galleryName       = "xstudio"
        definitionName    = "WinCluster"
        resourceGroupName = "ArtistAnywhere.Image"
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
      priority = {
        standard = {
          allocationStrategy = "LowestPrice"
          capacityTarget     = 2
          capacityMinimum    = 1
        }
        spot = {
          allocationStrategy = "PriceCapacityOptimized"
          evictionPolicy     = "Delete"
          capacityTarget     = 0
          capacityMinimum    = 0
          capacityMaintain = {
            enable = true
          }
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
        monitor = {
          enable = false
          name   = "Monitor"
        }
      }
      adminLogin = {
        userName     = ""
        userPassword = ""
        sshKeyPublic = ""
      }
    }
    network = {
      subnetName = "Cluster"
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
      }
      locationExtended = {
        enable = false
      }
    }
  }
]

##############################################################################
# Container Apps (https://learn.microsoft.com/azure/container-apps/overview) #
##############################################################################

containerAppEnvironments = [
  {
    enable = false
    name   = "xstudio"
    workloadProfile = {
      name = "Consumption"
      type = "D4"
      instanceCount = {
        minimum = 0
        maximum = 0
      }
    }
    network = {
      subnetName = "App"
      internalOnly = {
        enable = true
      }
      locationExtended = {
        enable = false
      }
    }
    registry = {
      host = "xstudio.azurecr.io"
      login = {
        userName     = ""
        userPassword = ""
      }
    }
    apps = [
      {
        enable = true
        name   = "lnx-cluster-cpu"
        container = {
          name   = "lnx-cluster-cpu"
          image  = "xstudio.azurecr.io/lnx-cluster-cpu:latest"
          memory = "0.5Gi"
          cpu    = 0.25
        }
        revisionMode = {
          type = "Single"
        }
      },
      {
        enable = true
        name   = "win-cluster-cpu"
        container = {
          name   = "win-cluster-cpu"
          image  = "xstudio.azurecr.io/win-cluster-cpu:latest"
          memory = "0.5Gi"
          cpu    = 0.25
        }
        revisionMode = {
          type = "Single"
        }
      }
    ]
    zoneRedundancy = {
      enable = false
    }
  }
]

####################################################################################
# Kubernetes Fleet   (https://learn.microsoft.com/azure/kubernetes-fleet/overview) #
# Kubernetes Service (https://learn.microsoft.com/azure/aks/what-is-aks)           #
####################################################################################

kubernetes = {
  enable = false
  fleetManager = {
    name      = "xstudio"
    dnsPrefix = ""
  }
  clusters = [
    {
      enable    = false
      name      = "" # "cpu"
      dnsPrefix = ""
      systemNodePool = {
        name = "sys"
        machine = {
          size  = "Standard_F8s_v2"
          count = 2
        }
      }
      userNodePools = [
        {
          name = "app"
          machine = {
            size  = "Standard_HX176rs"
            count = 2
          }
          spot = {
            enable         = true     # https://learn.microsoft.com/azure/virtual-machine-scale-sets/use-spot
            evictionPolicy = "Delete" # https://learn.microsoft.com/azure/virtual-machine-scale-sets/use-spot#eviction-policy
          }
        }
      ]
    },
    {
      enable    = false
      name      = "" # "gpu"
      dnsPrefix = ""
      systemNodePool = {
        name = "sys"
        machine = {
          size  = "Standard_F8s_v2"
          count = 2
        }
      }
      userNodePools = [
        {
          name = "app"
          machine = {
            size  = "Standard_NV72ads_A10_v5"
            count = 2
          }
          spot = {
            enable         = true     # https://learn.microsoft.com/azure/virtual-machine-scale-sets/use-spot
            evictionPolicy = "Delete" # https://learn.microsoft.com/azure/virtual-machine-scale-sets/use-spot#eviction-policy
          }
        }
      ]
    }
  ]
}

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

containerRegistry = {
  enable            = true
  name              = "xstudio"
  resourceGroupName = "ArtistAnywhere.Image.Registry"
}
