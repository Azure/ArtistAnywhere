resourceGroupName = "ArtistAnywhere.Image" # Alphanumeric, underscores, hyphens, periods and parenthesis are allowed

###############################################################################################
# Compute Gallery (https://learn.microsoft.com/azure/virtual-machines/shared-image-galleries) #
###############################################################################################

computeGallery = {
  name = "xstudio"
  imageDefinitions = [
    {
      name       = "Linux"
      type       = "Linux"
      generation = "V2"
      publisher  = "AlmaLinux"
      offer      = "AlmaLinux-x86_64"
      sku        = "9-Gen2"
    },
    {
      name       = "WinServer"
      type       = "Windows"
      generation = "V2"
      publisher  = "MicrosoftWindowsServer"
      offer      = "WindowsServer"
      sku        = "2022-Datacenter-Azure-Edition"
    },
    {
      name       = "WinCluster"
      type       = "Windows"
      generation = "V2"
      publisher  = "MicrosoftWindowsDesktop"
      offer      = "Windows-10"
      sku        = "Win10-22H2-Ent-G2"
    },
    {
      name       = "WinArtist"
      type       = "Windows"
      generation = "V2"
      publisher  = "MicrosoftWindowsDesktop"
      offer      = "Windows-11"
      sku        = "Win11-23H2-Ent"
    }
  ]
}

#############################################################################################
# Image Builder (https://learn.microsoft.com/azure/virtual-machines/image-builder-overview) #
#############################################################################################

imageBuilder = {
  binHostUrl = "https://xstudio.blob.core.windows.net/bin"
  templates = [
    {
      enable = true
      name   = "LnxJobScheduler"
      source = {
        imageDefinition = {
          name = "Linux"
        }
      }
      build = {
        machineType    = "Scheduler"
        machineSize    = "Standard_D8as_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = ""                 # NVIDIA or AMD
        imageVersion   = "1.0.0"
        osDiskSizeGB   = 1024
        timeoutMinutes = 180
        jobSchedulers = [
          "Slurm",
          "Deadline"
        ]
        jobProcessors = [
        ]
      }
      distribute = {
        replicaCount       = 1
        storageAccountType = "Premium_LRS"
      }
      errorHandling = {
        validationMode    = "cleanup"
        customizationMode = "cleanup"
      }
    },
    {
      enable = true
      name   = "LnxClusterCPU"
      source = {
        imageDefinition = {
          name = "Linux"
        }
      }
      build = {
        machineType    = "Cluster"
        machineSize    = "Standard_HX176rs" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = ""                 # NVIDIA or AMD
        imageVersion   = "2.0.0"
        osDiskSizeGB   = 480
        timeoutMinutes = 180
        jobSchedulers = [
          "Slurm",
          "Deadline"
        ]
        jobProcessors = [
          "PBRT"
        ]
      }
      distribute = {
        replicaCount       = 1
        storageAccountType = "Premium_LRS"
      }
      errorHandling = {
        validationMode    = "cleanup"
        customizationMode = "cleanup"
      }
    },
    {
      enable = true
      name   = "LnxClusterGPU-N"
      source = {
        imageDefinition = {
          name = "Linux"
        }
      }
      build = {
        machineType    = "Cluster"
        machineSize    = "Standard_NC40ads_H100_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = "NVIDIA"                   # NVIDIA or AMD
        imageVersion   = "2.1.0"
        osDiskSizeGB   = 1024
        timeoutMinutes = 180
        jobSchedulers = [
          "Slurm",
          "Deadline"
        ]
        jobProcessors = [
          "PBRT",
          "Blender"
        ]
      }
      distribute = {
        storageAccountType = "Premium_LRS"
        replicaCount       = 1
      }
      errorHandling = {
        validationMode    = "cleanup"
        customizationMode = "cleanup"
      }
    },
    {
      enable = true
      name   = "LnxClusterGPU-A"
      source = {
        imageDefinition = {
          name = "Linux"
        }
      }
      build = {
        machineType    = "Cluster"
        machineSize    = "Standard_ND96isr_MI300X_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = "AMD"                        # NVIDIA or AMD
        imageVersion   = "2.2.0"
        osDiskSizeGB   = 1024
        timeoutMinutes = 180
        jobSchedulers = [
          "Slurm",
          "Deadline"
        ]
        jobProcessors = [
          "PBRT",
          "Blender"
        ]
      }
      distribute = {
        replicaCount       = 1
        storageAccountType = "Premium_LRS"
      }
      errorHandling = {
        validationMode    = "cleanup"
        customizationMode = "cleanup"
      }
    },
    {
      enable = true
      name   = "LnxArtistGN"
      source = {
        imageDefinition = {
          name = "Linux"
        }
      }
      build = {
        machineType    = "Workstation"
        machineSize    = "Standard_NV72ads_A10_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = "NVIDIA"                  # NVIDIA or AMD
        imageVersion   = "3.0.0"
        osDiskSizeGB   = 1024
        timeoutMinutes = 180
        jobSchedulers = [
          "Slurm",
          "Deadline"
        ]
        jobProcessors = [
          "PBRT",
          "Blender"
        ]
      }
      distribute = {
        replicaCount       = 1
        storageAccountType = "Premium_LRS"
      }
      errorHandling = {
        validationMode    = "cleanup"
        customizationMode = "cleanup"
      }
    },
    {
      enable = true
      name   = "LnxArtistGA"
      source = {
        imageDefinition = {
          name = "Linux"
        }
      }
      build = {
        machineType    = "Workstation"
        machineSize    = "Standard_NV28adms_V710_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = "AMD"                       # NVIDIA or AMD
        imageVersion   = "3.1.0"
        osDiskSizeGB   = 1024
        timeoutMinutes = 180
        jobSchedulers = [
          "Slurm",
          "Deadline"
        ]
        jobProcessors = [
          "PBRT",
          "Blender"
        ]
      }
      distribute = {
        replicaCount       = 1
        storageAccountType = "Premium_LRS"
      }
      errorHandling = {
        validationMode    = "cleanup"
        customizationMode = "cleanup"
      }
    },
    {
      enable = true
      name   = "WinJobScheduler"
      source = {
        imageDefinition = {
          name = "WinServer"
        }
      }
      build = {
        machineType    = "Scheduler"
        machineSize    = "Standard_D8as_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = ""                 # NVIDIA or AMD
        imageVersion   = "1.0.0"
        osDiskSizeGB   = 1024
        timeoutMinutes = 180
        jobSchedulers = [
          "Slurm",
          "Deadline"
        ]
        jobProcessors = [
        ]
      }
      distribute = {
        storageAccountType = "Premium_LRS"
        replicaCount       = 1
      }
      errorHandling = {
        validationMode    = "cleanup"
        customizationMode = "cleanup"
      }
    },
    {
      enable = true
      name   = "WinClusterCPU"
      source = {
        imageDefinition = {
          name = "WinCluster"
        }
      }
      build = {
        machineType    = "Cluster"
        machineSize    = "Standard_HX176rs" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = ""                 # NVIDIA or AMD
        imageVersion   = "2.0.0"
        osDiskSizeGB   = 480
        timeoutMinutes = 360
        jobSchedulers = [
          "Slurm",
          "Deadline"
        ]
        jobProcessors = [
          "PBRT"
        ]
      }
      distribute = {
        storageAccountType = "Premium_LRS"
        replicaCount       = 1
      }
      errorHandling = {
        validationMode    = "cleanup"
        customizationMode = "cleanup"
      }
    },
    {
      enable = true
      name   = "WinClusterGPU-N"
      source = {
        imageDefinition = {
          name = "WinCluster"
        }
      }
      build = {
        machineType    = "Cluster"
        machineSize    = "Standard_NC40ads_H100_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = "NVIDIA"                   # NVIDIA or AMD
        imageVersion   = "2.1.0"
        osDiskSizeGB   = 1024
        timeoutMinutes = 360
        jobSchedulers = [
          "Slurm",
          "Deadline"
        ]
        jobProcessors = [
          "PBRT",
          "Blender"
        ]
      }
      distribute = {
        storageAccountType = "Premium_LRS"
        replicaCount       = 1
      }
      errorHandling = {
        validationMode    = "cleanup"
        customizationMode = "cleanup"
      }
    },
    {
      enable = true
      name   = "WinClusterGPU-A"
      source = {
        imageDefinition = {
          name = "WinCluster"
        }
      }
      build = {
        machineType    = "Cluster"
        machineSize    = "Standard_ND96isr_MI300X_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = "AMD"                        # NVIDIA or AMD
        imageVersion   = "2.2.0"
        osDiskSizeGB   = 1024
        timeoutMinutes = 360
        jobSchedulers = [
          "Slurm",
          "Deadline"
        ]
        jobProcessors = [
          "PBRT",
          "Blender"
        ]
      }
      distribute = {
        storageAccountType = "Premium_LRS"
        replicaCount       = 1
      }
      errorHandling = {
        validationMode    = "cleanup"
        customizationMode = "cleanup"
      }
    },
    {
      enable = true
      name   = "WinArtistGN"
      source = {
        imageDefinition = {
          name = "WinArtist"
        }
      }
      build = {
        machineType    = "Workstation"
        machineSize    = "Standard_NV72ads_A10_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = "NVIDIA"                  # NVIDIA or AMD
        imageVersion   = "3.0.0"
        osDiskSizeGB   = 1024
        timeoutMinutes = 360
        jobSchedulers = [
          "Slurm",
          "Deadline"
        ]
        jobProcessors = [
          "PBRT",
          "Blender"
        ]
      }
      distribute = {
        storageAccountType = "Premium_LRS"
        replicaCount       = 1
      }
      errorHandling = {
        validationMode    = "cleanup"
        customizationMode = "cleanup"
      }
    },
    {
      enable = true
      name   = "WinArtistGA"
      source = {
        imageDefinition = {
          name = "WinArtist"
        }
      }
      build = {
        machineType    = "Workstation"
        machineSize    = "Standard_NV28adms_V710_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = "AMD"                       # NVIDIA or AMD
        imageVersion   = "3.1.0"
        osDiskSizeGB   = 1024
        timeoutMinutes = 360
        jobSchedulers = [
          "Slurm",
          "Deadline"
        ]
        jobProcessors = [
          "PBRT",
          "Blender"
        ]
      }
      distribute = {
        storageAccountType = "Premium_LRS"
        replicaCount       = 1
      }
      errorHandling = {
        validationMode    = "cleanup"
        customizationMode = "cleanup"
      }
    }
  ]
}
