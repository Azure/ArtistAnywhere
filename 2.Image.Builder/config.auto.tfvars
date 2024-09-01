resourceGroupName = "ArtistAnywhere.Image" # Alphanumeric, underscores, hyphens, periods and parenthesis are allowed

###############################################################################################
# Compute Gallery (https://learn.microsoft.com/azure/virtual-machines/shared-image-galleries) #
###############################################################################################

computeGallery = {
  name = "xstudio"
  platform = {
    linux = {
      enable  = true
      version = "9.3.20231113"
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
      publisher  = "RESF"
      offer      = "RockyLinux-x86_64"
      sku        = "9-Base"
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
      name       = "WinFarm"
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
      name   = "LnxStorage"
      source = {
        imageDefinition = {
          name = "Linux"
        }
        # imageVersion = {
        #   id = ""
        # }
      }
      build = {
        machineType    = "Storage"
        machineSize    = "Standard_L8s_v3" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = ""                # NVIDIA or AMD
        imageVersion   = "0.0.0"
        osDiskSizeGB   = 0
        timeoutMinutes = 120
        jobProcessors = [
        ]
      }
      distribute = {
        replicaCount       = 3
        storageAccountType = "Standard_LRS"
      }
      errorHandling = {
        validationMode    = "cleanup"
        customizationMode = "cleanup"
      }
    },
    {
      enable = true
      name   = "LnxJobManager"
      source = {
        imageDefinition = {
          name = "Linux"
        }
        # imageVersion = {
        #   id = ""
        # }
      }
      build = {
        machineType    = "JobManager"
        machineSize    = "Standard_E8s_v4" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = ""                # NVIDIA or AMD
        imageVersion   = "1.0.0"
        osDiskSizeGB   = 256
        timeoutMinutes = 120
        jobProcessors = [
        ]
      }
      distribute = {
        replicaCount       = 3
        storageAccountType = "Standard_LRS"
      }
      errorHandling = {
        validationMode    = "cleanup"
        customizationMode = "cleanup"
      }
    },
    {
      enable = true
      name   = "LnxFarmC"
      source = {
        imageDefinition = {
          name = "Linux"
        }
        # imageVersion = {
        #   id = ""
        # }
      }
      build = {
        machineType    = "Farm"
        machineSize    = "Standard_HB176rs_v4" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = ""                    # NVIDIA or AMD
        imageVersion   = "2.0.0"
        osDiskSizeGB   = 480
        timeoutMinutes = 240
        jobProcessors = [
          "PBRT"
        ]
      }
      distribute = {
        replicaCount       = 3
        storageAccountType = "Standard_LRS"
      }
      errorHandling = {
        validationMode    = "cleanup"
        customizationMode = "cleanup"
      }
    },
    {
      enable = true
      name   = "LnxFarmGN"
      source = {
        imageDefinition = {
          name = "Linux"
        }
        # imageVersion = {
        #   id = ""
        # }
      }
      build = {
        machineType    = "Farm"
        machineSize    = "Standard_NV72ads_A10_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = "NVIDIA"                  # NVIDIA or AMD
        imageVersion   = "2.1.0"
        osDiskSizeGB   = 1024
        timeoutMinutes = 240
        jobProcessors = [
          "PBRT",
          "Blender"
        ]
      }
      distribute = {
        replicaCount       = 3
        storageAccountType = "Standard_LRS"
      }
      errorHandling = {
        validationMode    = "cleanup"
        customizationMode = "cleanup"
      }
    },
    {
      enable = false
      name   = "LnxFarmGA"
      source = {
        imageDefinition = {
          name = "Linux"
        }
        # imageVersion = {
        #   id = ""
        # }
      }
      build = {
        machineType    = "Farm"
        machineSize    = "Standard_NG32ads_V620_v1" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = "NVIDIA"                  # NVIDIA or AMD
        imageVersion   = "2.2.0"
        osDiskSizeGB   = 1024
        timeoutMinutes = 240
        jobProcessors = [
          "PBRT",
          "Blender"
        ]
      }
      distribute = {
        replicaCount       = 3
        storageAccountType = "Standard_LRS"
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
        # imageVersion = {
        #   id = ""
        # }
      }
      build = {
        machineType    = "Workstation"
        machineSize    = "Standard_NV72ads_A10_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = "NVIDIA"                  # NVIDIA or AMD
        imageVersion   = "3.0.0"
        osDiskSizeGB   = 1024
        timeoutMinutes = 240
        jobProcessors = [
          "PBRT",
          "Blender"
        ]
      }
      distribute = {
        replicaCount       = 3
        storageAccountType = "Standard_LRS"
      }
      errorHandling = {
        validationMode    = "cleanup"
        customizationMode = "cleanup"
      }
    },
    {
      enable = false
      name   = "LnxArtistGA"
      source = {
        imageDefinition = {
          name = "Linux"
        }
        # imageVersion = {
        #   id = ""
        # }
      }
      build = {
        machineType    = "Workstation"
        machineSize    = "Standard_NG32ads_V620_v1" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = "AMD"                      # NVIDIA or AMD
        imageVersion   = "3.1.0"
        osDiskSizeGB   = 1024
        timeoutMinutes = 240
        jobProcessors = [
          "PBRT",
          "Blender"
        ]
      }
      distribute = {
        replicaCount       = 3
        storageAccountType = "Standard_LRS"
      }
      errorHandling = {
        validationMode    = "cleanup"
        customizationMode = "cleanup"
      }
    },
    {
      enable = true
      name   = "WinJobManager"
      source = {
        imageDefinition = {
          name = "WinServer"
        }
        # imageVersion = {
        #   id = ""
        # }
      }
      build = {
        machineType    = "JobManager"
        machineSize    = "Standard_E8s_v4" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = ""                # NVIDIA or AMD
        imageVersion   = "1.0.0"
        osDiskSizeGB   = 256
        timeoutMinutes = 240
        jobProcessors = [
        ]
      }
      distribute = {
        replicaCount       = 3
        storageAccountType = "Standard_LRS"
      }
      errorHandling = {
        validationMode    = "cleanup"
        customizationMode = "cleanup"
      }
    },
    {
      enable = true
      name   = "WinFarmC"
      source = {
        imageDefinition = {
          name = "WinFarm"
        }
        # imageVersion = {
        #   id = ""
        # }
      }
      build = {
        machineType    = "Farm"
        machineSize    = "Standard_HB176rs_v4" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = ""                    # NVIDIA or AMD
        imageVersion   = "2.0.0"
        osDiskSizeGB   = 480
        timeoutMinutes = 360
        jobProcessors = [
          "PBRT"
        ]
      }
      distribute = {
        replicaCount       = 3
        storageAccountType = "Standard_LRS"
      }
      errorHandling = {
        validationMode    = "cleanup"
        customizationMode = "cleanup"
      }
    },
    {
      enable = true
      name   = "WinFarmGN"
      source = {
        imageDefinition = {
          name = "WinFarm"
        }
        # imageVersion = {
        #   id = ""
        # }
      }
      build = {
        machineType    = "Farm"
        machineSize    = "Standard_NV72ads_A10_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = ""                        # NVIDIA or AMD
        imageVersion   = "2.1.0"
        osDiskSizeGB   = 1024
        timeoutMinutes = 480
        jobProcessors = [
          "PBRT",
          "Blender"
        ]
      }
      distribute = {
        replicaCount       = 3
        storageAccountType = "Standard_LRS"
      }
      errorHandling = {
        validationMode    = "cleanup"
        customizationMode = "cleanup"
      }
    },
    {
      enable = false
      name   = "WinFarmGA"
      source = {
        imageDefinition = {
          name = "WinFarm"
        }
        # imageVersion = {
        #   id = ""
        # }
      }
      build = {
        machineType    = "Farm"
        machineSize    = "Standard_NG32ads_V620_v1" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = ""                        # NVIDIA or AMD
        imageVersion   = "2.2.0"
        osDiskSizeGB   = 1024
        timeoutMinutes = 480
        jobProcessors = [
          "PBRT",
          "Blender"
        ]
      }
      distribute = {
        replicaCount       = 3
        storageAccountType = "Standard_LRS"
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
        # imageVersion = {
        #   id = ""
        # }
      }
      build = {
        machineType    = "Workstation"
        machineSize    = "Standard_NV72ads_A10_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = "NVIDIA"                  # NVIDIA or AMD
        imageVersion   = "3.0.0"
        osDiskSizeGB   = 1024
        timeoutMinutes = 480
        jobProcessors = [
          "PBRT",
          "Blender"
        ]
      }
      distribute = {
        replicaCount       = 3
        storageAccountType = "Standard_LRS"
      }
      errorHandling = {
        validationMode    = "cleanup"
        customizationMode = "cleanup"
      }
    },
    {
      enable = false
      name   = "WinArtistGA"
      source = {
        imageDefinition = {
          name = "WinArtist"
        }
        # imageVersion = {
        #   id = ""
        # }
      }
      build = {
        machineType    = "Workstation"
        machineSize    = "Standard_NG32ads_V620_v1" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = "AMD"                      # NVIDIA or AMD
        imageVersion   = "3.1.0"
        osDiskSizeGB   = 1024
        timeoutMinutes = 480
        jobProcessors = [
          "PBRT",
          "Blender"
        ]
      }
      distribute = {
        replicaCount       = 3
        storageAccountType = "Standard_LRS"
      }
      errorHandling = {
        validationMode    = "cleanup"
        customizationMode = "cleanup"
      }
    }
  ]
}

imageCustomize = { # Enables or disables image build customization scripts
  core         = true
  jobManager   = true
  jobProcessor = true
}

binStorage = { # Required for image build customization script access
  host = ""
  auth = ""
}
