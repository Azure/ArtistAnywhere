############################################################################
# Batch (https://learn.microsoft.com/azure/batch/batch-technical-overview) #
############################################################################

batch = {
  enable = false
  account = {
    name       = "xstudio"
    subnetName = "Farm"
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
          enable = false
        }
      }
      node = {
        container = {
          enable   = false
          id       = "lnx-farm-c:pbrt"
          registry = "xstudio.azurecr.io"
          image = {
            publisher = "almalinux"
            offer     = "almalinux"
            sku       = "8-gen2"
            version   = "latest"
            agentId   = "batch.node.el 8"
          }
        }
        image = {
          id      = "/subscriptions/5cc0d8f1-3643-410c-8646-1a2961134bd3/resourceGroups/ArtistAnywhere.Image/providers/Microsoft.Compute/galleries/xstudio/images/Linux/versions/2.0.0"
          agentId = "batch.node.el 8"
        }
        machine = {
          size  = "Standard_HB120rs_v3" # https://learn.microsoft.com/azure/batch/batch-pool-vm-sizes
          count = 2
        }
        network = {
          subnetName = "Farm"
          acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
            enable = true
          }
        }
        osDisk = {
          ephemeral = { # https://learn.microsoft.com/azure/batch/create-pool-ephemeral-os-disk
            enable = false
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
          enable = false
        }
      }
      node = {
        container = {
          enable   = false
          id       = "lnx-farm-g:pbrt"
          registry = "xstudio.azurecr.io"
          image = {
            publisher = "almalinux"
            offer     = "almalinux"
            sku       = "8-gen2"
            version   = "latest"
            agentId   = "batch.node.el 8"
          }
        }
        image = {
          id      = "/subscriptions/5cc0d8f1-3643-410c-8646-1a2961134bd3/resourceGroups/ArtistAnywhere.Image/providers/Microsoft.Compute/galleries/xstudio/images/Linux/versions/2.1.0"
          agentId = "batch.node.el 8"
        }
        machine = {
          size  = "Standard_NV36ads_A10_v5" # https://learn.microsoft.com/azure/batch/batch-pool-vm-sizes
          count = 2
        }
        network = {
          subnetName = "Farm"
          acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
            enable = true
          }
        }
        osDisk = {
          ephemeral = { # https://learn.microsoft.com/azure/batch/create-pool-ephemeral-os-disk
            enable = false
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
          enable = false
        }
      }
      node = {
        container = {
          enable   = false
          id       = "win-farm-c:pbrt"
          registry = "xstudio.azurecr.io"
          image = {
            publisher = "mirantis"
            offer     = "windows_2022_with_mirantis_container_runtime"
            sku       = "win_2022_mcr_20_10"
            version   = "latest"
            agentId   = "batch.node.windows amd64"
          }
        }
        image = {
          id      = "/subscriptions/5cc0d8f1-3643-410c-8646-1a2961134bd3/resourceGroups/ArtistAnywhere.Image/providers/Microsoft.Compute/galleries/xstudio/images/WinFarm/versions/2.0.0"
          agentId = "batch.node.windows amd64"
        }
        machine = {
          size  = "Standard_HB120rs_v3" # https://learn.microsoft.com/azure/batch/batch-pool-vm-sizes
          count = 2
        }
        network = {
          subnetName = "Farm"
          acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
            enable = true
          }
        }
        osDisk = {
          ephemeral = { # https://learn.microsoft.com/azure/batch/create-pool-ephemeral-os-disk
            enable = false
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
          enable = false
        }
      }
      node = {
        container = {
          enable   = false
          id       = "win-farm-g:pbrt"
          registry = "xstudio.azurecr.io"
          image = {
            publisher = "mirantis"
            offer     = "windows_2022_with_mirantis_container_runtime"
            sku       = "win_2022_mcr_20_10"
            version   = "latest"
            agentId   = "batch.node.windows amd64"
          }
        }
        image = {
          id      = "/subscriptions/5cc0d8f1-3643-410c-8646-1a2961134bd3/resourceGroups/ArtistAnywhere.Image/providers/Microsoft.Compute/galleries/xstudio/images/WinFarm/versions/2.1.0"
          agentId = "batch.node.windows amd64"
        }
        machine = {
          size  = "Standard_NV36ads_A10_v5" # https://learn.microsoft.com/azure/batch/batch-pool-vm-sizes
          count = 2
        }
        network = {
          subnetName = "Farm"
          acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
            enable = true
          }
        }
        osDisk = {
          ephemeral = { # https://learn.microsoft.com/azure/batch/create-pool-ephemeral-os-disk
            enable = false
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
