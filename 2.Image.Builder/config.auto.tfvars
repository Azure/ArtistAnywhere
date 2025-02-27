resourceGroupName = "ArtistAnywhere.Image" # Alphanumeric, underscores, hyphens, periods and parenthesis are allowed

###############################################################################################
# Compute Gallery (https://learn.microsoft.com/azure/virtual-machines/shared-image-galleries) #
###############################################################################################

computeGallery = {
  name = "xstudio"
  platform = {
    linux = {
      enable  = true
      version = "9.5.202411260"
    }
    windows = {
      enable  = true
      version = "Latest"
    }
  }
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
        machineType    = "JobScheduler"
        machineSize    = "Standard_D8as_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = ""                 # NVIDIA or AMD
        imageVersion   = "1.0.0"
        osDiskSizeGB   = 1024
        timeoutMinutes = 180
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
      name   = "LnxClusterC"
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
      name   = "LnxClusterGN"
      source = {
        imageDefinition = {
          name = "Linux"
        }
      }
      build = {
        machineType    = "Cluster"
        machineSize    = "Standard_NC40ads_H100_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = "NVIDIA"                   # NVIDIA, NVIDIA.GRID or AMD
        imageVersion   = "2.1.0"
        osDiskSizeGB   = 1024
        timeoutMinutes = 180
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
      name   = "LnxClusterGA"
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
        gpuProvider    = "NVIDIA.GRID"             # NVIDIA, NVIDIA.GRID or AMD
        imageVersion   = "3.0.0"
        osDiskSizeGB   = 1024
        timeoutMinutes = 180
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
      name   = "WinADDC"
      source = {
        imageDefinition = {
          name = "WinServer"
        }
      }
      build = {
        machineType    = "DomainController"
        machineSize    = "Standard_D8as_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = ""                 # NVIDIA or AMD
        imageVersion   = "0.0.0"
        osDiskSizeGB   = 1024
        timeoutMinutes = 180
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
      name   = "WinJobScheduler"
      source = {
        imageDefinition = {
          name = "WinServer"
        }
      }
      build = {
        machineType    = "JobScheduler"
        machineSize    = "Standard_D8as_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = ""                 # NVIDIA or AMD
        imageVersion   = "1.0.0"
        osDiskSizeGB   = 1024
        timeoutMinutes = 180
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
      name   = "WinClusterC"
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
      name   = "WinClusterGN"
      source = {
        imageDefinition = {
          name = "WinCluster"
        }
      }
      build = {
        machineType    = "Cluster"
        machineSize    = "Standard_NC40ads_H100_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = "NVIDIA"                   # NVIDIA, NVIDIA.GRID or AMD
        imageVersion   = "2.1.0"
        osDiskSizeGB   = 1024
        timeoutMinutes = 360
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
      name   = "WinClusterGA"
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
        gpuProvider    = "NVIDIA.GRID"             # NVIDIA, NVIDIA.GRID or AMD
        imageVersion   = "3.0.0"
        osDiskSizeGB   = 1024
        timeoutMinutes = 360
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

imageCustomize = {
  storage = {
    binHostUrl = "https://xstudio.blob.core.windows.net/bin"
    authClient = { # Required for image customization build process
      id     = ""
      secret = ""
    }
  }
  script = { # Enables or disables image customization build scripts
    jobScheduler = {
      deadline = true
      slurm    = false
    }
    jobProcessor = {
      render = true
      eda    = false
    }
  }
}

######################################################################################################
# Container Registry (https://learn.microsoft.com/azure/container-registry/container-registry-intro) #
######################################################################################################

containerRegistry = {
  enable = true
  name   = "xai00"
  type   = "Premium"
  adminUser = {
    enable = true
  }
  dataEndpoint = {
    enable = true
  }
  zoneRedundancy = {
    enable = true
  }
  quarantinePolicy = {
    enable = true
  }
  exportPolicy = {
    enable = true
  }
  trustPolicy = {
    enable = true
  }
  anonymousPull = {
    enable = true
  }
  encryption = {
    enable = false
  }
  retentionPolicy = {
    days = 7
  }
  firewallRules = [
    {
      action  = "Allow"
      ipRange = "40.124.64.0/25"
    }
  ]
  replicationRegions = [
    {
      name = "WestUS"
      regionEndpoint = {
        enable = true
      }
      zoneRedundancy = {
        enable = false
      }
    }
  ]
}

####################################################################################################################
# Container Registry Task (https://learn.microsoft.com/azure/container-registry/container-registry-tasks-overview) #
####################################################################################################################

containerRegistryTasks = [
  {
    enable = true
    name   = "LnxClusterC"
    type   = "Linux"
    docker = {
      context = {
        hostUrl     = "https://github.com/Azure/ArtistAnywhere.git"
        accessToken = " "
      }
      filePath    = "2.Image.Builder/Docker/LnxClusterC"
      imageNames = [
        "lnx-cluster-c"
      ]
      cache = {
        enable = false
      }
    }
  },
  {
    enable = true
    name   = "WinClusterC"
    type   = "Windows"
    docker = {
      context = {
        hostUrl     = "https://github.com/Azure/ArtistAnywhere.git"
        accessToken = " "
      }
      filePath = "2.Image.Builder/Docker/WinClusterC"
      imageNames = [
        "win-cluster-c"
      ]
      cache = {
        enable = false
      }
    }
  }
]
