resourceGroupName = "AAA.Image.Registry"

######################################################################################################
# Container Registry (https://learn.microsoft.com/azure/container-registry/container-registry-intro) #
######################################################################################################

containerRegistry = {
  name = "hpcai"
  tier = "Premium"
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
      action  = "Allow" # Task Agent
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
  tasks = [
    {
      enable = true
      name   = "JobClusterXLC"
      type   = "Linux"
      docker = {
        context = {
          hostUrl     = "https://github.com/Azure/ArtistAnywhere.git"
          accessToken = " "
        }
        filePath    = "2.Image/Registry/Docker/JobClusterXLC"
        imageNames = [
          "job-cluster-xlc"
        ]
        cache = {
          enable = false
        }
      }
      agentPool = {
        enable = true
        name   = "hpcai"
      }
      timeout = {
        seconds = 3600
      }
    },
    {
      enable = true
      name   = "JobClusterXWC"
      type   = "Windows"
      docker = {
        context = {
          hostUrl     = "https://github.com/Azure/ArtistAnywhere.git"
          accessToken = " "
        }
        filePath = "2.Image/Registry/Docker/JobClusterXWC"
        imageNames = [
          "job-cluster-xwc"
        ]
        cache = {
          enable = false
        }
      }
      agentPool = {
        enable = true
        name   = "hpcai"
      }
      timeout = {
        seconds = 3600
      }
    }
  ]
  agentPools =[
    {
      enable = true
      name   = "hpcai"
      type   = "S1"
      count  = 1
    }
  ]
}
