resourceGroupName = "ArtistAnywhere.Farm" # Alphanumeric, underscores, hyphens, periods and parenthesis are allowed

######################################################################################################
# Virtual Machine Scale Sets (https://learn.microsoft.com/azure/virtual-machine-scale-sets/overview) #
######################################################################################################

virtualMachineScaleSets = [
  {
    enable = false
    name = {
      prefix = "LnxFarmC"
      suffix = {
        enable = true
      }
    }
    machine = {
      size  = "Standard_HB120rs_v3"
      count = 2
      image = {
        id = "/subscriptions/5cc0d8f1-3643-410c-8646-1a2961134bd3/resourceGroups/ArtistAnywhere.Image/providers/Microsoft.Compute/galleries/xstudio/images/Linux/versions/2.0.0"
        plan = {
          enable    = false
          publisher = ""
          product   = ""
          name      = ""
        }
      }
    }
    spot = {
      enable         = true     # https://learn.microsoft.com/azure/virtual-machine-scale-sets/use-spot
      evictionPolicy = "Delete" # https://learn.microsoft.com/azure/virtual-machine-scale-sets/use-spot#eviction-policy
      tryRestore = {
        enable  = false # https://learn.microsoft.com/azure/virtual-machine-scale-sets/use-spot#try--restore
        timeout = "PT1H"
      }
    }
    network = {
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
      }
    }
    operatingSystem = {
      type = "Linux"
      disk = {
        storageType = "Standard_LRS"
        cachingType = "ReadOnly"
        sizeGB      = 0
        ephemeral = { # https://learn.microsoft.com/azure/virtual-machines/ephemeral-os-disks
          enable    = true
          placement = "ResourceDisk"
        }
      }
    }
    adminLogin = {
      userName     = ""
      userPassword = ""
      sshPublicKey = "" # "ssh-rsa ..."
      passwordAuth = {
        disable = false
      }
    }
    extension = {
      initialize = {
        enable   = true
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
        protocol    = "tcp"
        port        = 111
        requestPath = ""
      }
      monitor = {
        enable = false
      }
    }
    flexibleOrchestration = {
      enable           = false # https://learn.microsoft.com/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-orchestration-modes
      faultDomainCount = 1     # https://learn.microsoft.com/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-manage-fault-domains
    }
  },
  {
    enable = false
    name = {
      prefix = "LnxFarmG"
      suffix = {
        enable = true
      }
    }
    machine = {
      size  = "Standard_NV36ads_A10_v5"
      count = 2
      image = {
        id = "/subscriptions/5cc0d8f1-3643-410c-8646-1a2961134bd3/resourceGroups/ArtistAnywhere.Image/providers/Microsoft.Compute/galleries/xstudio/images/Linux/versions/2.1.0"
        plan = {
          enable    = false
          publisher = ""
          product   = ""
          name      = ""
        }
      }
    }
    spot = {
      enable         = true     # https://learn.microsoft.com/azure/virtual-machine-scale-sets/use-spot
      evictionPolicy = "Delete" # https://learn.microsoft.com/azure/virtual-machine-scale-sets/use-spot#eviction-policy
      tryRestore = {
        enable  = false # https://learn.microsoft.com/azure/virtual-machine-scale-sets/use-spot#try--restore
        timeout = "PT1H"
      }
    }
    network = {
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
      }
    }
    operatingSystem = {
      type = "Linux"
      disk = {
        storageType = "Standard_LRS"
        cachingType = "ReadOnly"
        sizeGB      = 0
        ephemeral = { # https://learn.microsoft.com/azure/virtual-machines/ephemeral-os-disks
          enable    = true
          placement = "ResourceDisk"
        }
      }
    }
    adminLogin = {
      userName     = ""
      userPassword = ""
      sshPublicKey = "" # "ssh-rsa ..."
      passwordAuth = {
        disable = false
      }
    }
    extension = {
      initialize = {
        enable   = true
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
        protocol    = "tcp"
        port        = 111
        requestPath = ""
      }
      monitor = {
        enable = false
      }
    }
    flexibleOrchestration = {
      enable           = false # https://learn.microsoft.com/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-orchestration-modes
      faultDomainCount = 1     # https://learn.microsoft.com/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-manage-fault-domains
    }
  },
  {
    enable = false
    name = {
      prefix = "WinFarmC"
      suffix = {
        enable = true
      }
    }
    machine = {
      size  = "Standard_HB120rs_v3"
      count = 2
      image = {
        id = "/subscriptions/5cc0d8f1-3643-410c-8646-1a2961134bd3/resourceGroups/ArtistAnywhere.Image/providers/Microsoft.Compute/galleries/xstudio/images/WinFarm/versions/2.0.0"
        plan = {
          enable    = false
          publisher = ""
          product   = ""
          name      = ""
        }
      }
    }
    spot = {
      enable         = true     # https://learn.microsoft.com/azure/virtual-machine-scale-sets/use-spot
      evictionPolicy = "Delete" # https://learn.microsoft.com/azure/virtual-machine-scale-sets/use-spot#eviction-policy
      tryRestore = {
        enable  = false # https://learn.microsoft.com/azure/virtual-machine-scale-sets/use-spot#try--restore
        timeout = "PT1H"
      }
    }
    network = {
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
      }
    }
    operatingSystem = {
      type = "Windows"
      disk = {
        storageType = "Standard_LRS"
        cachingType = "ReadOnly"
        sizeGB      = 0
        ephemeral = { # https://learn.microsoft.com/azure/virtual-machines/ephemeral-os-disks
          enable    = true
          placement = "ResourceDisk"
        }
      }
    }
    adminLogin = {
      userName     = ""
      userPassword = ""
      sshPublicKey = "" # "ssh-rsa ..."
      passwordAuth = {
        disable = false
      }
    }
    extension = {
      initialize = {
        enable   = true
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
        protocol    = "tcp"
        port        = 445
        requestPath = ""
      }
      monitor = {
        enable = false
      }
    }
    flexibleOrchestration = {
      enable           = false # https://learn.microsoft.com/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-orchestration-modes
      faultDomainCount = 1     # https://learn.microsoft.com/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-manage-fault-domains
    }
  },
  {
    enable = false
    name = {
      prefix = "WinFarmG"
      suffix = {
        enable = true
      }
    }
    machine = {
      size  = "Standard_NV36ads_A10_v5"
      count = 2
      image = {
        id = "/subscriptions/5cc0d8f1-3643-410c-8646-1a2961134bd3/resourceGroups/ArtistAnywhere.Image/providers/Microsoft.Compute/galleries/xstudio/images/WinFarm/versions/2.1.0"
        plan = {
          enable    = false
          publisher = ""
          product   = ""
          name      = ""
        }
      }
    }
    spot = {
      enable         = true     # https://learn.microsoft.com/azure/virtual-machine-scale-sets/use-spot
      evictionPolicy = "Delete" # https://learn.microsoft.com/azure/virtual-machine-scale-sets/use-spot#eviction-policy
      tryRestore = {
        enable  = false # https://learn.microsoft.com/azure/virtual-machine-scale-sets/use-spot#try--restore
        timeout = "PT1H"
      }
    }
    network = {
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
      }
    }
    operatingSystem = {
      type = "Windows"
      disk = {
        storageType = "Standard_LRS"
        cachingType = "ReadOnly"
        sizeGB      = 0
        ephemeral = { # https://learn.microsoft.com/azure/virtual-machines/ephemeral-os-disks
          enable    = true
          placement = "ResourceDisk"
        }
      }
    }
    adminLogin = {
      userName     = ""
      userPassword = ""
      sshPublicKey = "" # "ssh-rsa ..."
      passwordAuth = {
        disable = false
      }
    }
    extension = {
      initialize = {
        enable   = true
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
        protocol    = "tcp"
        port        = 445
        requestPath = ""
      }
      monitor = {
        enable = false
      }
    }
    flexibleOrchestration = {
      enable           = false # https://learn.microsoft.com/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-orchestration-modes
      faultDomainCount = 1     # https://learn.microsoft.com/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-manage-fault-domains
    }
  }
]

############################################################################
# Batch (https://learn.microsoft.com/azure/batch/batch-technical-overview) #
############################################################################

batch = {
  enable = false
  account = {
    name = "xstudio"
    storage = {
      accountName       = ""
      resourceGroupName = ""
    }
  }
  pools = [
    {
      enable = false
      name = {
        display = "Linux Render Farm (CPU)"
        prefix  = "LnxFarmC"
        suffix = {
          enable = true
        }
      }
      node = {
        imageId = "/subscriptions/5cc0d8f1-3643-410c-8646-1a2961134bd3/resourceGroups/ArtistAnywhere.Image/providers/Microsoft.Compute/galleries/xstudio/images/Linux/versions/2.0.0"
        agentId = "batch.node.el 9"
        machine = {
          size  = "Standard_HB120rs_v3" # https://learn.microsoft.com/azure/batch/batch-pool-vm-sizes
          count = 2
        }
        network = {
          acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
            enable = true
          }
        }
        osDisk = {
          ephemeral = {
            enable = false # https://learn.microsoft.com/azure/batch/create-pool-ephemeral-os-disk
          }
        }
        adminLogin = {
          userName     = ""
          userPassword = ""
        }
        placementPolicy    = "Regional"       # https://learn.microsoft.com/rest/api/batchservice/pool/add?#nodeplacementpolicytype
        deallocationMode   = "TaskCompletion" # https://learn.microsoft.com/rest/api/batchservice/pool/remove-nodes?#computenodedeallocationoption
        maxConcurrentTasks = 3
      }
      fillMode = { # https://learn.microsoft.com/azure/batch/batch-parallel-node-tasks
        nodePack = {
          enable = true
        }
      }
      spot = { # https://learn.microsoft.com/azure/batch/batch-spot-vms
        enable = true
      }
    },
    {
      enable = false
      name = {
        display = "Linux Render Farm (GPU)"
        prefix  = "LnxFarmG"
        suffix = {
          enable = true
        }
      }
      node = {
        imageId = "/subscriptions/5cc0d8f1-3643-410c-8646-1a2961134bd3/resourceGroups/ArtistAnywhere.Image/providers/Microsoft.Compute/galleries/xstudio/images/Linux/versions/2.1.0"
        agentId = "batch.node.el 9"
        machine = {
          size  = "Standard_NV36ads_A10_v5" # https://learn.microsoft.com/azure/batch/batch-pool-vm-sizes
          count = 2
        }
        network = {
          acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
            enable = true
          }
        }
        osDisk = {
          ephemeral = {
            enable = false # https://learn.microsoft.com/azure/batch/create-pool-ephemeral-os-disk
          }
        }
        adminLogin = {
          userName     = ""
          userPassword = ""
        }
        placementPolicy    = "Regional"       # https://learn.microsoft.com/rest/api/batchservice/pool/add?#nodeplacementpolicytype
        deallocationMode   = "TaskCompletion" # https://learn.microsoft.com/rest/api/batchservice/pool/remove-nodes?#computenodedeallocationoption
        maxConcurrentTasks = 3
      }
      fillMode = { # https://learn.microsoft.com/azure/batch/batch-parallel-node-tasks
        nodePack = {
          enable = true
        }
      }
      spot = { # https://learn.microsoft.com/azure/batch/batch-spot-vms
        enable = true
      }
    },
    {
      enable = false
      name = {
        display = "Windows Render Farm (CPU)"
        prefix  = "WinFarmC"
        suffix = {
          enable = true
        }
      }
      node = {
        imageId = "/subscriptions/5cc0d8f1-3643-410c-8646-1a2961134bd3/resourceGroups/ArtistAnywhere.Image/providers/Microsoft.Compute/galleries/xstudio/images/WinFarm/versions/2.0.0"
        agentId = "batch.node.windows amd64"
        machine = {
          size  = "Standard_HB120rs_v3" # https://learn.microsoft.com/azure/batch/batch-pool-vm-sizes
          count = 2
        }
        network = {
          acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
            enable = true
          }
        }
        osDisk = {
          ephemeral = {
            enable = false # https://learn.microsoft.com/azure/batch/create-pool-ephemeral-os-disk
          }
        }
        adminLogin = {
          userName     = ""
          userPassword = ""
        }
        placementPolicy    = "Regional"       # https://learn.microsoft.com/rest/api/batchservice/pool/add?#nodeplacementpolicytype
        deallocationMode   = "TaskCompletion" # https://learn.microsoft.com/rest/api/batchservice/pool/remove-nodes?#computenodedeallocationoption
        maxConcurrentTasks = 3
      }
      fillMode = { # https://learn.microsoft.com/azure/batch/batch-parallel-node-tasks
        nodePack = {
          enable = true
        }
      }
      spot = { # https://learn.microsoft.com/azure/batch/batch-spot-vms
        enable = true
      }
    },
    {
      enable = false
      name = {
        display = "Windows Render Farm (GPU)"
        prefix  = "WinFarmG"
        suffix = {
          enable = true
        }
      }
      node = {
        imageId = "/subscriptions/5cc0d8f1-3643-410c-8646-1a2961134bd3/resourceGroups/ArtistAnywhere.Image/providers/Microsoft.Compute/galleries/xstudio/images/WinFarm/versions/2.1.0"
        agentId = "batch.node.windows amd64"
        machine = {
          size  = "Standard_NV36ads_A10_v5" # https://learn.microsoft.com/azure/batch/batch-pool-vm-sizes
          count = 2
        }
        network = {
          acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
            enable = true
          }
        }
        osDisk = {
          ephemeral = {
            enable = false # https://learn.microsoft.com/azure/batch/create-pool-ephemeral-os-disk
          }
        }
        adminLogin = {
          userName     = ""
          userPassword = ""
        }
        placementPolicy    = "Regional"       # https://learn.microsoft.com/rest/api/batchservice/pool/add?#nodeplacementpolicytype
        deallocationMode   = "TaskCompletion" # https://learn.microsoft.com/rest/api/batchservice/pool/remove-nodes?#computenodedeallocationoption
        maxConcurrentTasks = 3
      }
      fillMode = { # https://learn.microsoft.com/azure/batch/batch-parallel-node-tasks
        nodePack = {
          enable = true
        }
      }
      spot = { # https://learn.microsoft.com/azure/batch/batch-spot-vms
        enable = true
      }
    }
  ]
}

################################################################################
# Azure OpenAI (https://learn.microsoft.com/azure/ai-services/openai/overview) #
################################################################################

azureOpenAI = {
  enable      = false
  regionName  = "EastUS"
  accountName = "xstudio"
  domainName  = ""
  serviceTier = "S0"
  chatDeployment = {
    model = {
      name    = "gpt-35-turbo"
      format  = "OpenAI"
      version = ""
      scale   = "Standard"
    }
    session = {
      context = ""
      request = ""
    }
  }
  imageGeneration = {
    description = ""
    height      = 1024
    width       = 1024
  }
  storage = {
    enable = false
  }
}

#####################################################
# https://learn.microsoft.com/azure/azure-functions #
#####################################################

functionApp = {
  enable = false
  name   = "xstudio"
  servicePlan = {
    computeTier = "S1"
    workerCount = 2
    alwaysOn    = false
  }
  monitor = {
    workspace = {
      sku = "PerGB2018"
    }
    insight = {
      type = "web"
    }
    retentionDays = 90
  }
}

#######################################################################
# Resource dependency configuration for pre-existing deployments only #
#######################################################################

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
  subnetNameFarm    = ""
  subnetNameAI      = ""
  resourceGroupName = ""
}

existingStorage = {
  enable            = false
  name              = ""
  resourceGroupName = ""
  fileShareName     = ""
}
