resourceGroupName = "ArtistAnywhere.Image" # Alphanumeric, underscores, hyphens, periods and parenthesis are allowed

###############################################################################################
# Compute Gallery (https://learn.microsoft.com/azure/virtual-machines/shared-image-galleries) #
###############################################################################################

computeGallery = {
  name   = "xstudio"
  enable = true
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
      publisher  = "AlmaLinux"
      offer      = "AlmaLinux-x86_64"
      sku        = "8-Gen2"
    },
    {
      name       = "WinServer"
      type       = "Windows"
      generation = "V2"
      publisher  = "MicrosoftWindowsServer"
      offer      = "WindowsServer"
      sku        = "2022-Datacenter-G2"
    },
    {
      name       = "WinFarm"
      type       = "Windows"
      generation = "V2"
      publisher  = "MicrosoftWindowsDesktop"
      offer      = "Windows-10"
      sku        = "Win10-22H2-Pro-G2"
    },
    {
      name       = "WinArtist"
      type       = "Windows"
      generation = "V2"
      publisher  = "MicrosoftWindowsDesktop"
      offer      = "Windows-11"
      sku        = "Win11-23H2-Pro"
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
      name   = "LnxPlatform"
      enable = true
      source = {
        imageDefinition = {
          name    = "Linux"
          version = "Latest"
        }
        imageVersion = {
          id = ""
        }
      }
      build = {
        machineType    = ""
        machineSize    = "Standard_D8as_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = ""                 # NVIDIA or AMD
        imageVersion   = "0.0.0"
        osDiskSizeGB   = 0
        timeoutMinutes = 120
        renderEngines = [
        ]
        customization = [
          "systemctl --now disable firewalld",
          "sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config",
          "dnf -y install gcc gcc-c++ python3-devel perl openssl cmake git jq nfs-utils",
          "dnf -y upgrade",
          "export AZNFS_NONINTERACTIVE_INSTALL=1",
          "curl -L https://github.com/Azure/AZNFS-mount/releases/download/2.0.3/aznfs_install.sh | bash"
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
      name   = "LnxStorage"
      enable = true
      source = {
        imageDefinition = {
          name    = "Linux"
          version = "Latest"
        }
        imageVersion = {
          id = "/subscriptions/5cc0d8f1-3643-410c-8646-1a2961134bd3/resourceGroups/ArtistAnywhere.Image/providers/Microsoft.Compute/galleries/xstudio/images/Linux/versions/0.0.0"
        }
      }
      build = {
        machineType    = "Storage"
        machineSize    = "Standard_L8s_v3" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = ""                # NVIDIA or AMD
        imageVersion   = "0.1.0"
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
      name   = "LnxScheduler"
      enable = true
      source = {
        imageDefinition = {
          name    = "Linux"
          version = "Latest"
        }
        imageVersion = {
          id = "/subscriptions/5cc0d8f1-3643-410c-8646-1a2961134bd3/resourceGroups/ArtistAnywhere.Image/providers/Microsoft.Compute/galleries/xstudio/images/Linux/versions/0.0.0"
        }
      }
      build = {
        machineType    = "Scheduler"
        machineSize    = "Standard_D8as_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = ""                 # NVIDIA or AMD
        imageVersion   = "1.0.0"
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
      name   = "LnxFarmC"
      enable = true
      source = {
        imageDefinition = {
          name    = "Linux"
          version = "Latest"
        }
        imageVersion = {
          id = "/subscriptions/5cc0d8f1-3643-410c-8646-1a2961134bd3/resourceGroups/ArtistAnywhere.Image/providers/Microsoft.Compute/galleries/xstudio/images/Linux/versions/0.0.0"
        }
      }
      build = {
        machineType    = "Farm"
        machineSize    = "Standard_D96as_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = ""                  # NVIDIA or AMD
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
      name   = "LnxFarmG"
      enable = true
      source = {
        imageDefinition = {
          name    = "Linux"
          version = "Latest"
        }
        imageVersion = {
          id = "/subscriptions/5cc0d8f1-3643-410c-8646-1a2961134bd3/resourceGroups/ArtistAnywhere.Image/providers/Microsoft.Compute/galleries/xstudio/images/Linux/versions/0.0.0"
        }
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
      name   = "LnxArtistN"
      enable = true
      source = {
        imageDefinition = {
          name    = "Linux"
          version = "Latest"
        }
        imageVersion = {
          id = "/subscriptions/5cc0d8f1-3643-410c-8646-1a2961134bd3/resourceGroups/ArtistAnywhere.Image/providers/Microsoft.Compute/galleries/xstudio/images/Linux/versions/0.0.0"
        }
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
      name   = "LnxArtistA"
      enable = false
      source = {
        imageDefinition = {
          name    = "Linux"
          version = "Latest"
        }
        imageVersion = {
          id = "/subscriptions/5cc0d8f1-3643-410c-8646-1a2961134bd3/resourceGroups/ArtistAnywhere.Image/providers/Microsoft.Compute/galleries/xstudio/images/Linux/versions/0.0.0"
        }
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
      name   = "WinScheduler"
      enable = true
      source = {
        imageDefinition = {
          name    = "WinServer"
          version = "Latest"
        }
        imageVersion = {
          id = ""
        }
      }
      build = {
        machineType    = "Scheduler"
        machineSize    = "Standard_D8as_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = ""                 # NVIDIA or AMD
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
      name   = "WinFarmC"
      enable = true
      source = {
        imageDefinition = {
          name    = "WinFarm"
          version = "Latest"
        }
        imageVersion = {
          id = ""
        }
      }
      build = {
        machineType    = "Farm"
        machineSize    = "Standard_D96as_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = ""                  # NVIDIA or AMD
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
      name   = "WinFarmG"
      enable = true
      source = {
        imageDefinition = {
          name    = "WinFarm"
          version = "Latest"
        }
        imageVersion = {
          id = ""
        }
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
      name   = "WinArtistN"
      enable = true
      source = {
        imageDefinition = {
          name    = "WinArtist"
          version = "Latest"
        }
        imageVersion = {
          id = ""
        }
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
      name   = "WinArtistA"
      enable = false
      source = {
        imageDefinition = {
          name    = "WinArtist"
          version = "Latest"
        }
        imageVersion = {
          id = ""
        }
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
  renderBlender     = "4.0.2"
  renderMaya        = "2024_0_1"
  renderHoudini     = "20.0.506"
  renderUnrealVS    = "2022"
  renderUnreal      = "5.3.2"
  renderUnrealPixel = "5.3-1.0.1"
  jobScheduler      = "10.3.1.4"
  pcoipAgent        = "23.12"
}

jobDatabase = {
  host = ""
  port = 27017 # 10255
}

binStorage = { # Required configuration for image building
  host = ""
  auth = ""
}

#######################################################################
# Resource dependency configuration for pre-existing deployments only #
#######################################################################

existingKeyVault = {
  enable            = false
  name              = ""
  resourceGroupName = ""
}

existingNetwork = {
  enable            = false
  name              = ""
  subnetName        = ""
  resourceGroupName = ""
}
