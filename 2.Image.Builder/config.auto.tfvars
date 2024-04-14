resourceGroupName = "ArtistAnywhere.Image" # Alphanumeric, underscores, hyphens, periods and parenthesis are allowed

###############################################################################################
# Compute Gallery (https://learn.microsoft.com/azure/virtual-machines/shared-image-galleries) #
###############################################################################################

computeGallery = {
  name = "xstudio"
  platform = {
    linux = {
      enable = true
    }
    windows = {
      enable = true
    }
  }
  imageDefinitions = [
    {
      name       = "Linux"
      type       = "Linux"
      generation = "V2"
      publisher  = "RESF"
      offer      = "RockyLinux-x86_64"
      sku        = "8-Base"
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
  appDefinitions = [
    {
      name = "LnxPBRT"
      type = "Linux"
    },
    {
      name = "LnxBlender"
      type = "Linux"
    },
    {
      name = "WinPBRT"
      type = "Windows"
    },
    {
      name = "WinBlender"
      type = "Windows"
    },
    {
      name = "WinUnreal"
      type = "Windows"
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
          name    = "Linux"
          version = "Latest"
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
        renderEngines = [
        ]
        customization = [
        ]
      }
      distribute = {
        replicaCount       = 3
        storageAccountType = "Premium_LRS"
      }
      errorHandling = {
        validationMode    = "cleanup"
        customizationMode = "cleanup"
      }
    },
    {
      enable = true
      name   = "LnxScheduler"
      source = {
        imageDefinition = {
          name    = "Linux"
          version = "Latest"
        }
        # imageVersion = {
        #   id = ""
        # }
      }
      build = {
        machineType    = "Scheduler"
        machineSize    = "Standard_E8s_v4" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = ""                # NVIDIA or AMD
        imageVersion   = "1.0.0"
        osDiskSizeGB   = 30
        timeoutMinutes = 120
        renderEngines = [
        ]
        customization = [
        ]
      }
      distribute = {
        replicaCount       = 3
        storageAccountType = "Premium_LRS"
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
          name    = "Linux"
          version = "Latest"
        }
        # imageVersion = {
        #   id = ""
        # }
      }
      build = {
        machineType    = "Farm"
        machineSize    = "Standard_F72s_v2" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = ""                 # NVIDIA or AMD
        imageVersion   = "2.0.0"
        osDiskSizeGB   = 360
        timeoutMinutes = 240
        renderEngines = [
          "PBRT"
        ]
        customization = [
        ]
      }
      distribute = {
        replicaCount       = 3
        storageAccountType = "Premium_LRS"
      }
      errorHandling = {
        validationMode    = "cleanup"
        customizationMode = "cleanup"
      }
    },
    {
      enable = true
      name   = "LnxFarmG"
      source = {
        imageDefinition = {
          name    = "Linux"
          version = "Latest"
        }
        # imageVersion = {
        #   id = ""
        # }
      }
      build = {
        machineType    = "Farm"
        machineSize    = "Standard_NV36ads_A10_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = "NVIDIA"                  # NVIDIA or AMD
        imageVersion   = "2.1.0"
        osDiskSizeGB   = 360
        timeoutMinutes = 240
        renderEngines = [
          "PBRT",
          "Blender"
        ]
        customization = [
        ]
      }
      distribute = {
        replicaCount       = 3
        storageAccountType = "Premium_LRS"
      }
      errorHandling = {
        validationMode    = "cleanup"
        customizationMode = "cleanup"
      }
    },
    {
      enable = true
      name   = "LnxArtistN"
      source = {
        imageDefinition = {
          name    = "Linux"
          version = "Latest"
        }
        # imageVersion = {
        #   id = ""
        # }
      }
      build = {
        machineType    = "Workstation"
        machineSize    = "Standard_NV36ads_A10_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = "NVIDIA"                  # NVIDIA or AMD
        imageVersion   = "3.0.0"
        osDiskSizeGB   = 360
        timeoutMinutes = 240
        renderEngines = [
          "PBRT",
          "Blender"
        ]
        customization = [
        ]
      }
      distribute = {
        replicaCount       = 3
        storageAccountType = "Premium_LRS"
      }
      errorHandling = {
        validationMode    = "cleanup"
        customizationMode = "cleanup"
      }
    },
    {
      enable = false
      name   = "LnxArtistA"
      source = {
        imageDefinition = {
          name    = "Linux"
          version = "Latest"
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
        osDiskSizeGB   = 360
        timeoutMinutes = 240
        renderEngines = [
          "PBRT",
          "Blender"
        ]
        customization = [
        ]
      }
      distribute = {
        replicaCount       = 3
        storageAccountType = "Premium_LRS"
      }
      errorHandling = {
        validationMode    = "cleanup"
        customizationMode = "cleanup"
      }
    },
    {
      enable = true
      name   = "WinScheduler"
      source = {
        imageDefinition = {
          name    = "WinServer"
          version = "Latest"
        }
        # imageVersion = {
        #   id = ""
        # }
      }
      build = {
        machineType    = "Scheduler"
        machineSize    = "Standard_E8s_v4" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = ""                # NVIDIA or AMD
        imageVersion   = "1.0.0"
        osDiskSizeGB   = 0
        timeoutMinutes = 240
        renderEngines = [
        ]
        customization = [
        ]
      }
      distribute = {
        replicaCount       = 3
        storageAccountType = "Premium_LRS"
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
          name    = "WinFarm"
          version = "Latest"
        }
        # imageVersion = {
        #   id = ""
        # }
      }
      build = {
        machineType    = "Farm"
        machineSize    = "Standard_F72s_v2" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = ""                 # NVIDIA or AMD
        imageVersion   = "2.0.0"
        osDiskSizeGB   = 360
        timeoutMinutes = 360
        renderEngines = [
          "PBRT"
        ]
        customization = [
        ]
      }
      distribute = {
        replicaCount       = 3
        storageAccountType = "Premium_LRS"
      }
      errorHandling = {
        validationMode    = "cleanup"
        customizationMode = "cleanup"
      }
    },
    {
      enable = true
      name   = "WinFarmG"
      source = {
        imageDefinition = {
          name    = "WinFarm"
          version = "Latest"
        }
        # imageVersion = {
        #   id = ""
        # }
      }
      build = {
        machineType    = "Farm"
        machineSize    = "Standard_NV36ads_A10_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = ""                        # NVIDIA or AMD
        imageVersion   = "2.1.0"
        osDiskSizeGB   = 512
        timeoutMinutes = 480
        renderEngines = [
          "PBRT",
          "Blender",
          # "Unreal"
        ]
        customization = [
        ]
      }
      distribute = {
        replicaCount       = 3
        storageAccountType = "Premium_LRS"
      }
      errorHandling = {
        validationMode    = "cleanup"
        customizationMode = "cleanup"
      }
    },
    {
      enable = true
      name   = "WinArtistN"
      source = {
        imageDefinition = {
          name    = "WinArtist"
          version = "Latest"
        }
        # imageVersion = {
        #   id = ""
        # }
      }
      build = {
        machineType    = "Workstation"
        machineSize    = "Standard_NV36ads_A10_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = "NVIDIA"                  # NVIDIA or AMD
        imageVersion   = "3.0.0"
        osDiskSizeGB   = 512
        timeoutMinutes = 480
        renderEngines = [
          "PBRT",
          "Blender",
          # "Unreal+PixelStream"
        ]
        customization = [
        ]
      }
      distribute = {
        replicaCount       = 3
        storageAccountType = "Premium_LRS"
      }
      errorHandling = {
        validationMode    = "cleanup"
        customizationMode = "cleanup"
      }
    },
    {
      enable = false
      name   = "WinArtistA"
      source = {
        imageDefinition = {
          name    = "WinArtist"
          version = "Latest"
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
        osDiskSizeGB   = 512
        timeoutMinutes = 480
        renderEngines = [
          "PBRT",
          "Blender",
          # "Unreal+PixelStream"
        ]
        customization = [
        ]
      }
      distribute = {
        replicaCount       = 3
        storageAccountType = "Premium_LRS"
      }
      errorHandling = {
        validationMode    = "cleanup"
        customizationMode = "cleanup"
      }
    }
  ]
}

versionPath = {
  nvidiaCUDA        = "12.3.2"
  nvidiaCUDAToolkit = "v12.3"
  nvidiaOptiX       = "8.0.0"
  renderPBRT        = "v4"
  renderBlender     = "4.1.0"
  renderMaya        = "2024_0_1"
  renderHoudini     = "20.0.506"
  renderUnrealVS    = "2022"
  renderUnreal      = "5.3.2"
  renderUnrealPixel = "5.3-1.0.1"
  jobScheduler      = "10.3.2.1"
  pcoipAgent        = "23.12.8"
}

dataPlatform = {
  adminLogin = {
    userName     = "xadmin"
    userPassword = "P@ssword1234"
  }
  jobDatabase = {
    host = ""
    port = 27017 # 10255
    serviceLogin = {
      userName     = "dbuser"
      userPassword = "P@ssword1234"
    }
  }
}

binStorage = { # Required configuration for image building
  host = "https://xstudio.blob.core.windows.net/bin"
  auth = "?sv=2023-01-03&st=2024-01-01T00%3A00%3A00Z&se=9999-12-31T00%3A00%3A00Z&sp=r&ss=btqf&srt=sco&sig=rBOirh1igdW1AoUWVKgKRj2oL%2FCKN6cLlSWbtIW1IVY%3D"
}
