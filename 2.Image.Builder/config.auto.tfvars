resourceGroupName = "ArtistAnywhere.Image" # Alphanumeric, underscores, hyphens, periods and parenthesis are allowed

######################################################################################################
# Container Registry (https://learn.microsoft.com/azure/container-registry/container-registry-intro) #
######################################################################################################

containerRegistry = {
  enable = true
  name   = "xstudio"
  sku    = "Premium"
}

###############################################################################################
# Compute Gallery (https://learn.microsoft.com/azure/virtual-machines/shared-image-galleries) #
###############################################################################################

computeGallery = {
  enable = true
  name   = "xstudio"
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
      sku        = "Win11-22H2-Pro"
    }
  ]
}

#############################################################################################
# Image Builder (https://learn.microsoft.com/azure/virtual-machines/image-builder-overview) #
#############################################################################################

imageBuilder = {
  templates = [
    {
      name = "LnxPlatform"
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
          "dnf -y install gcc gcc-c++ python3-devel perl cmake git jq nfs-utils",
          "dnf -y upgrade"
        ]
      }
      errorHandling = {
        validationMode    = "cleanup"
        customizationMode = "cleanup"
      }
    },
    {
      name = "LnxStorageC"
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
      errorHandling = {
        validationMode    = "cleanup"
        customizationMode = "cleanup"
      }
    },
    {
      name = "LnxStorageG"
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
        machineSize    = "Standard_NG8ads_V620_v1" # https://learn.microsoft.com/azure/virtual-machines/sizes
        gpuProvider    = "AMD"                     # NVIDIA or AMD
        imageVersion   = "0.2.0"
        osDiskSizeGB   = 0
        timeoutMinutes = 120
        renderEngines = [
        ]
        customization = [
        ]
      }
      errorHandling = {
        validationMode    = "cleanup"
        customizationMode = "cleanup"
      }
    },
    {
      name = "LnxScheduler"
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
      errorHandling = {
        validationMode    = "cleanup"
        customizationMode = "cleanup"
      }
    },
    {
      name = "LnxFarmC"
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
          "PBRT",
          "RenderMan"
        ]
        customization = [
        ]
      }
      errorHandling = {
        validationMode    = "cleanup"
        customizationMode = "cleanup"
      }
    },
    {
      name = "LnxFarmG"
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
          "Blender",
          "RenderMan"
        ]
        customization = [
        ]
      }
      errorHandling = {
        validationMode    = "cleanup"
        customizationMode = "cleanup"
      }
    },
    {
      name = "LnxArtistN"
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
          "Blender",
          "RenderMan"
        ]
        customization = [
        ]
      }
      errorHandling = {
        validationMode    = "cleanup"
        customizationMode = "cleanup"
      }
    },
    # {
    #   name = "LnxArtistA"
    #   source = {
    #     imageDefinition = {
    #       name    = "Linux"
    #       version = "Latest"
    #     }
    #     imageVersion = {
    #       id = "/subscriptions/5cc0d8f1-3643-410c-8646-1a2961134bd3/resourceGroups/ArtistAnywhere.Image/providers/Microsoft.Compute/galleries/xstudio/images/Linux/versions/0.0.0"
    #     }
    #   }
    #   build = {
    #     machineType    = "Workstation"
    #     machineSize    = "Standard_NG32ads_V620_v1" # https://learn.microsoft.com/azure/virtual-machines/sizes
    #     gpuProvider    = "AMD"                      # NVIDIA or AMD
    #     imageVersion   = "3.1.0"
    #     osDiskSizeGB   = 360
    #     timeoutMinutes = 240
    #     renderEngines = [
    #       "PBRT",
    #       "Blender",
    #       "RenderMan"
    #     ]
    #     customization = [
    #     ]
    #   }
    #   errorHandling = {
    #     validationMode    = "cleanup"
    #     customizationMode = "cleanup"
    #   }
    # },
    {
      name = "WinScheduler"
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
      errorHandling = {
        validationMode    = "cleanup"
        customizationMode = "cleanup"
      }
    },
    {
      name = "WinFarmC"
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
          "PBRT",
          "RenderMan"
        ]
        customization = [
        ]
      }
      errorHandling = {
        validationMode    = "cleanup"
        customizationMode = "cleanup"
      }
    },
    {
      name = "WinFarmG"
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
          "RenderMan",
          # "Unreal"
        ]
        customization = [
        ]
      }
      errorHandling = {
        validationMode    = "cleanup"
        customizationMode = "cleanup"
      }
    },
    {
      name = "WinArtistN"
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
          "RenderMan",
          # "Unreal+PixelStream"
        ]
        customization = [
        ]
      }
      errorHandling = {
        validationMode    = "cleanup"
        customizationMode = "cleanup"
      }
    },
    # {
    #   name = "WinArtistA"
    #   source = {
    #     imageDefinition = {
    #       name    = "WinArtist"
    #       version = "Latest"
    #     }
    #     imageVersion = {
    #       id = ""
    #     }
    #   }
    #   build = {
    #     machineType    = "Workstation"
    #     machineSize    = "Standard_NG32ads_V620_v1" # https://learn.microsoft.com/azure/virtual-machines/sizes
    #     gpuProvider    = "AMD"                      # NVIDIA or AMD
    #     imageVersion   = "3.1.0"
    #     osDiskSizeGB   = 512
    #     timeoutMinutes = 480
    #     renderEngines = [
    #       "PBRT",
    #       "Blender",
    #       "RenderMan",
    #       # "Unreal+PixelStream"
    #     ]
    #     customization = [
    #     ]
    #   }
    #   errorHandling = {
    #     validationMode    = "cleanup"
    #     customizationMode = "cleanup"
    #   }
    # }
  ]
}

binStorage = {
  host = ""
  auth = ""
}

#######################################################################
# Resource dependency configuration for pre-existing deployments only #
#######################################################################

existingNetwork = {
  enable            = false
  name              = ""
  subnetName        = ""
  resourceGroupName = ""
}
