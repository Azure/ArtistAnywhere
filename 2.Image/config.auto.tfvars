resourceGroupName = "AAA.Image"

image = {
  linux = {
    version = "9.5.202411260"
    x64 = {
      publisher = "AlmaLinux"
      offer     = "AlmaLinux-x86_64"
      sku       = "9-Gen2"
    }
    arm = {
      publisher = "AlmaLinux"
      offer     = "AlmaLinux-ARM"
      sku       = "9-ARM-Gen2"
    }
  }
  windows = {
    version = "Latest"
    cluster = {
      enable = true
    }
  }
}

###############################################################################################
# Compute Gallery (https://learn.microsoft.com/azure/virtual-machines/shared-image-galleries) #
###############################################################################################

computeGallery = {
  name = "hpcai"
  imageDefinitions = [
    {
      name       = "LnxX"
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
      name       = "LnxA"
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
      name       = "WinServer"
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
      name       = "WinCluster"
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
      name       = "WinUser"
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
      name   = "JobManagerXL"
      source = {
        imageDefinition = {
          name = "LnxX"
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
      name   = "JobManagerAL"
      source = {
        imageDefinition = {
          name = "LnxA"
        }
      }
      build = {
        machineType    = "JobManager"
        machineSize    = "Standard_E8ps_v6" # https://learn.microsoft.com/azure/virtual-machines/sizes
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
      name   = "JobClusterXLCA"
      source = {
        imageDefinition = {
          name = "LnxX"
        }
      }
      build = {
        machineType    = "JobCluster"
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
      name   = "JobClusterXLCI"
      source = {
        imageDefinition = {
          name = "LnxX"
        }
      }
      build = {
        machineType    = "JobCluster"
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
      name   = "JobClusterXLGN"
      source = {
        imageDefinition = {
          name = "LnxX"
        }
      }
      build = {
        machineType    = "JobCluster"
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
      name   = "JobClusterXLGA"
      source = {
        imageDefinition = {
          name = "LnxX"
        }
      }
      build = {
        machineType    = "JobCluster"
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
      name   = "JobClusterAL"
      source = {
        imageDefinition = {
          name = "LnxA"
        }
      }
      build = {
        machineType    = "JobCluster"
        machineSize    = "Standard_E96ps_v6" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = ""                  # NVIDIA or AMD
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
      name   = "VDIUserXLGN"
      source = {
        imageDefinition = {
          name = "LnxX"
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
      name   = "VDIUserXLGA"
      source = {
        imageDefinition = {
          name = "LnxX"
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
      name   = "VDIUserAL"
      source = {
        imageDefinition = {
          name = "LnxA"
        }
      }
      build = {
        machineType    = "VDI"
        machineSize    = "Standard_E96ps_v6" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = ""                  # NVIDIA or AMD
        imageVersion   = "3.0.0"
        osDiskSizeGB   = 1024
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
      name   = "JobManagerXW"
      source = {
        imageDefinition = {
          name = "WinServer"
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
      name   = "JobManagerAW"
      source = {
        imageDefinition = {
          name = "WinServer"
        }
      }
      build = {
        machineType    = "JobManager"
        machineSize    = "Standard_E96ps_v6" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = ""                  # NVIDIA or AMD
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
      name   = "JobClusterXWCA"
      source = {
        imageDefinition = {
          name = "WinCluster"
        }
      }
      build = {
        machineType    = "JobCluster"
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
      name   = "JobClusterXWCI"
      source = {
        imageDefinition = {
          name = "WinCluster"
        }
      }
      build = {
        machineType    = "JobCluster"
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
      name   = "JobClusterXWGN"
      source = {
        imageDefinition = {
          name = "WinCluster"
        }
      }
      build = {
        machineType    = "JobCluster"
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
      name   = "JobClusterXWGA"
      source = {
        imageDefinition = {
          name = "WinCluster"
        }
      }
      build = {
        machineType    = "JobCluster"
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
      name   = "JobClusterAW"
      source = {
        imageDefinition = {
          name = "WinCluster"
        }
      }
      build = {
        machineType    = "JobCluster"
        machineSize    = "Standard_E96ps_v6" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = ""                  # NVIDIA or AMD
        imageVersion   = "2.0.0"
        osDiskSizeGB   = 1000
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
      name   = "VDIUserXWGN"
      source = {
        imageDefinition = {
          name = "WinUser"
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
      name   = "VDIUserXWGA"
      source = {
        imageDefinition = {
          name = "WinUser"
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
    },
    {
      enable = true
      name   = "VDIUserAW"
      source = {
        imageDefinition = {
          name = "WinUser"
        }
      }
      build = {
        machineType    = "VDI"
        machineSize    = "Standard_E96ps_v6" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = ""                  # NVIDIA or AMD
        imageVersion   = "3.0.0"
        osDiskSizeGB   = 1024
        timeoutMinutes = 360
        jobManagers = [
          "Slurm",
          "Deadline"
        ]
        jobProcessors = [
          "PBRT"
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
