resourceGroupName = "ArtistAnywhere.Image.Registry" # Alphanumeric, underscores, hyphens, periods and parenthesis are allowed

######################################################################################################
# Container Registry (https://learn.microsoft.com/azure/container-registry/container-registry-intro) #
######################################################################################################

containerRegistry = {
  name = "xstudio"
  type = "Premium"
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
    # {
    #   action  = "Allow"
    #   ipRange = "40.124.64.0/25"
    # }
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
    name   = "LnxClusterCPU"
    type   = "Linux"
    docker = {
      context = {
        hostUrl     = "https://github.com/Azure/ArtistAnywhere.git"
        accessToken = " "
      }
      filePath    = "2.Image.Builder/Registry/Docker/LnxClusterCPU"
      imageNames = [
        "lnx-cluster-cpu"
      ]
      cache = {
        enable = false
      }
    }
  },
  {
    enable = true
    name   = "WinClusterCPU"
    type   = "Windows"
    docker = {
      context = {
        hostUrl     = "https://github.com/Azure/ArtistAnywhere.git"
        accessToken = " "
      }
      filePath = "2.Image.Builder/Registry/Docker/WinClusterCPU"
      imageNames = [
        "win-cluster-cpu"
      ]
      cache = {
        enable = false
      }
    }
  }
]
