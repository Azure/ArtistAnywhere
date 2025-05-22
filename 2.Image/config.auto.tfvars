resourceGroupName = "AAA.Image"

###############################################################################################
# Compute Gallery (https://learn.microsoft.com/azure/virtual-machines/shared-image-galleries) #
###############################################################################################

computeGallery = {
  name = "hpcai"
  imageDefinitions = [
    {
      name       = "xLinux"
      type       = "Linux"
      generation = "V2"
      publisher  = "AlmaLinux"
      offer      = "AlmaLinux-x86_64"
      sku        = "9-Gen2"
      support = {
        networkAcceleration = true
        machineConfidential = false
        launchTrusted       = true
        hibernation         = true
        nvmeDisks           = true
      }
    },
    {
      name       = "aLinux"
      type       = "Linux"
      generation = "V2"
      publisher  = "AlmaLinux"
      offer      = "AlmaLinux-ARM"
      sku        = "9-ARM-Gen2"
      support = {
        networkAcceleration = true
        machineConfidential = false
        launchTrusted       = true
        hibernation         = true
        nvmeDisks           = true
      }
    },
    {
      name       = "WinJobManager"
      type       = "Windows"
      generation = "V2"
      publisher  = "MicrosoftWindowsServer"
      offer      = "WindowsServer"
      sku        = "2025-Datacenter-Azure-Edition"
      support = {
        networkAcceleration = true
        machineConfidential = false
        launchTrusted       = true
        hibernation         = false
        nvmeDisks           = false
      }
    },
    {
      name       = "WinJobCluster"
      type       = "Windows"
      generation = "V2"
      publisher  = "MicrosoftWindowsDesktop"
      offer      = "Windows-11"
      sku        = "Win11-24H2-Pro"
      support = {
        networkAcceleration = true
        machineConfidential = false
        launchTrusted       = true
        hibernation         = false
        nvmeDisks           = false
      }
    },
    {
      name       = "WinVDI"
      type       = "Windows"
      generation = "V2"
      publisher  = "MicrosoftWindowsDesktop"
      offer      = "Windows-11"
      sku        = "Win11-24H2-Ent"
      support = {
        networkAcceleration = true
        machineConfidential = false
        launchTrusted       = true
        hibernation         = true
        nvmeDisks           = true
      }
    }
  ]
}

#############################################################################################
# Image Builder (https://learn.microsoft.com/azure/virtual-machines/image-builder-overview) #
#############################################################################################

imageBuilder = {
  templates = [
    {
      enable = true
      name   = "LnxJobManager"
      source = {
        imageDefinition = {
          name = "xLinux"
        }
      }
      build = {
        machineType    = "JobManager"
        machineSize    = "Standard_D8as_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = ""                 # NVIDIA or AMD
        imageVersion   = "1.0.0"
        osDiskSizeGB   = 1024
        timeoutMinutes = 180
        jobManagers = [
          "Slurm",
          "Deadline"
        ]
        jobProcessors = [
        ]
      }
    },
    {
      enable = true
      name   = "LnxJobManagerARM"
      source = {
        imageDefinition = {
          name = "aLinux"
        }
      }
      build = {
        machineType    = "JobManager"
        machineSize    = "Standard_E4ps_v6" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = ""                 # NVIDIA or AMD
        imageVersion   = "1.0.0"
        osDiskSizeGB   = 1024
        timeoutMinutes = 180
        jobManagers = [
          "Slurm",
          "Deadline"
        ]
        jobProcessors = [
        ]
      }
    },
    {
      enable = true
      name   = "xLnxJobClusterCA"
      source = {
        imageDefinition = {
          name = "xLinux"
        }
      }
      build = {
        machineType    = "Cluster"
        machineSize    = "Standard_HX176rs" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = ""                 # NVIDIA or AMD
        imageVersion   = "2.0.0"
        osDiskSizeGB   = 480
        timeoutMinutes = 180
        jobManagers = [
          "Slurm",
          "Deadline"
        ]
        jobProcessors = [
          "PBRT"
        ]
      }
    },
    {
      enable = true
      name   = "xLnxJobClusterCI"
      source = {
        imageDefinition = {
          name = "xLinux"
        }
      }
      build = {
        machineType    = "Cluster"
        machineSize    = "Standard_FX96ms_v2" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = ""                   # NVIDIA or AMD
        imageVersion   = "2.1.0"
        osDiskSizeGB   = 480
        timeoutMinutes = 180
        jobManagers = [
          "Slurm",
          "Deadline"
        ]
        jobProcessors = [
          "PBRT"
        ]
      }
    },
    {
      enable = true
      name   = "xLnxJobClusterGN"
      source = {
        imageDefinition = {
          name = "xLinux"
        }
      }
      build = {
        machineType    = "Cluster"
        machineSize    = "Standard_NC40ads_H100_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = "NVIDIA"                   # NVIDIA or AMD
        imageVersion   = "2.2.0"
        osDiskSizeGB   = 320
        timeoutMinutes = 180
        jobManagers = [
          "Slurm",
          "Deadline"
        ]
        jobProcessors = [
          "PBRT",
          "Blender"
        ]
      }
    },
    {
      enable = true
      name   = "xLnxJobClusterGA"
      source = {
        imageDefinition = {
          name = "xLinux"
        }
      }
      build = {
        machineType    = "Cluster"
        machineSize    = "Standard_ND96isr_MI300X_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = "AMD"                        # NVIDIA or AMD
        imageVersion   = "2.3.0"
        osDiskSizeGB   = 1000
        timeoutMinutes = 180
        jobManagers = [
          "Slurm",
          "Deadline"
        ]
        jobProcessors = [
          "PBRT",
          "Blender"
        ]
      }
    },
    {
      enable = true
      name   = "xLnxVDIGN"
      source = {
        imageDefinition = {
          name = "xLinux"
        }
      }
      build = {
        machineType    = "VDI"
        machineSize    = "Standard_NV72ads_A10_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = "NVIDIA"                  # NVIDIA or AMD
        imageVersion   = "3.0.0"
        osDiskSizeGB   = 1024
        timeoutMinutes = 180
        jobManagers = [
          "Slurm",
          "Deadline"
        ]
        jobProcessors = [
          "PBRT",
          "Blender"
        ]
      }
    },
    {
      enable = true
      name   = "xLnxVDIGA"
      source = {
        imageDefinition = {
          name = "xLinux"
        }
      }
      build = {
        machineType    = "VDI"
        machineSize    = "Standard_NV28adms_V710_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = "AMD"                       # NVIDIA or AMD
        imageVersion   = "3.1.0"
        osDiskSizeGB   = 1024
        timeoutMinutes = 180
        jobManagers = [
          "Slurm",
          "Deadline"
        ]
        jobProcessors = [
          "PBRT",
          "Blender"
        ]
      }
    },
    {
      enable = true
      name   = "WinJobManager"
      source = {
        imageDefinition = {
          name = "WinJobManager"
        }
      }
      build = {
        machineType    = "JobManager"
        machineSize    = "Standard_D8as_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = ""                 # NVIDIA or AMD
        imageVersion   = "1.0.0"
        osDiskSizeGB   = 1024
        timeoutMinutes = 180
        jobManagers = [
          "Slurm",
          "Deadline"
        ]
        jobProcessors = [
        ]
      }
    },
    {
      enable = true
      name   = "WinJobClusterCA"
      source = {
        imageDefinition = {
          name = "WinJobCluster"
        }
      }
      build = {
        machineType    = "Cluster"
        machineSize    = "Standard_HX176rs" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = ""                 # NVIDIA or AMD
        imageVersion   = "2.0.0"
        osDiskSizeGB   = 480
        timeoutMinutes = 360
        jobManagers = [
          "Slurm",
          "Deadline"
        ]
        jobProcessors = [
          "PBRT"
        ]
      }
    },
    {
      enable = true
      name   = "WinJobClusterCI"
      source = {
        imageDefinition = {
          name = "WinJobCluster"
        }
      }
      build = {
        machineType    = "Cluster"
        machineSize    = "Standard_FX96ms_v2" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = ""                   # NVIDIA or AMD
        imageVersion   = "2.1.0"
        osDiskSizeGB   = 480
        timeoutMinutes = 360
        jobManagers = [
          "Slurm",
          "Deadline"
        ]
        jobProcessors = [
          "PBRT"
        ]
      }
    },
    {
      enable = true
      name   = "WinJobClusterGN"
      source = {
        imageDefinition = {
          name = "WinJobCluster"
        }
      }
      build = {
        machineType    = "Cluster"
        machineSize    = "Standard_NC40ads_H100_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = "NVIDIA"                   # NVIDIA or AMD
        imageVersion   = "2.2.0"
        osDiskSizeGB   = 320
        timeoutMinutes = 360
        jobManagers = [
          "Slurm",
          "Deadline"
        ]
        jobProcessors = [
          "PBRT",
          "Blender"
        ]
      }
    },
    {
      enable = true
      name   = "WinJobClusterGA"
      source = {
        imageDefinition = {
          name = "WinJobCluster"
        }
      }
      build = {
        machineType    = "Cluster"
        machineSize    = "Standard_ND96isr_MI300X_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = "AMD"                        # NVIDIA or AMD
        imageVersion   = "2.3.0"
        osDiskSizeGB   = 1000
        timeoutMinutes = 360
        jobManagers = [
          "Slurm",
          "Deadline"
        ]
        jobProcessors = [
          "PBRT",
          "Blender"
        ]
      }
    },
    {
      enable = true
      name   = "xWinVDIGN"
      source = {
        imageDefinition = {
          name = "xWinVDI"
        }
      }
      build = {
        machineType    = "VDI"
        machineSize    = "Standard_NV72ads_A10_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = "NVIDIA"                  # NVIDIA or AMD
        imageVersion   = "3.0.0"
        osDiskSizeGB   = 1024
        timeoutMinutes = 360
        jobManagers = [
          "Slurm",
          "Deadline"
        ]
        jobProcessors = [
          "PBRT",
          "Blender"
        ]
      }
    },
    {
      enable = true
      name   = "xWinVDIGA"
      source = {
        imageDefinition = {
          name = "xWinVDI"
        }
      }
      build = {
        machineType    = "VDI"
        machineSize    = "Standard_NV28adms_V710_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = "AMD"                       # NVIDIA or AMD
        imageVersion   = "3.1.0"
        osDiskSizeGB   = 1024
        timeoutMinutes = 360
        jobManagers = [
          "Slurm",
          "Deadline"
        ]
        jobProcessors = [
          "PBRT",
          "Blender"
        ]
      }
    }
  ]
  distribute = {
    replicaCount = 1
    replicaRegions = [
      "WestUS"
    ]
    storageAccount = {
      type = "Premium_LRS"
    }
  }
  errorHandling = {
    validationMode    = "cleanup"
    customizationMode = "cleanup"
  }
}

########################
# Brownfield Resources #
########################

virtualNetwork = {
  name              = "HPC"
  subnetName        = "Cluster"
  resourceGroupName = "AAA.Network.SouthCentralUS"
}
