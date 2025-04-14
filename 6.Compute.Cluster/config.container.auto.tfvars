##############################################################################
# Container Apps (https://learn.microsoft.com/azure/container-apps/overview) #
##############################################################################

containerAppEnvironments = [
  {
    enable = false
    name   = "xstudio"
    workloadProfiles = [
    ]
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
        enable = false
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
        enable = false
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
  },
  {
    enable = false
    name   = "xstudio-cpu"
    workloadProfiles = [
      {
        enable = true
        name   = "Consumption"
        type   = "Consumption"
        instanceCount = {
          minimum = 0
          maximum = 0
        }
      }
    ]
    network = {
      subnetName = "AppCPU"
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
        enable = false
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
        enable = false
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
  },
  {
    enable = false
    name   = "xstudio-gpu"
    workloadProfiles = [
      {
        enable = true
        name   = "Dedicated"
        type   = "D4"
        instanceCount = {
          minimum = 0
          maximum = 1
        }
      }
    ]
    network = {
      subnetName = "AppGPU"
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
        enable = false
        name   = "lnx-cluster-gpu"
        container = {
          name   = "lnx-cluster-gpu"
          image  = "xstudio.azurecr.io/lnx-cluster-gpu:latest"
          memory = "0.5Gi"
          cpu    = 0.25
        }
        revisionMode = {
          type = "Single"
        }
      },
      {
        enable = false
        name   = "win-cluster-gpu"
        container = {
          name   = "win-cluster-gpu"
          image  = "xstudio.azurecr.io/win-cluster-gpu:latest"
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
