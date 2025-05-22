##############################################################################
# Container Apps (https://learn.microsoft.com/azure/container-apps/overview) #
##############################################################################

containerAppEnvironments = [
  {
    enable = false
    name   = "hpcai"
    workloadProfiles = [
    ]
    network = {
      subnetName = "App"
      internalOnly = {
        enable = true
      }
    }
    apps = [
      {
        enable = false
        name   = "xlnx-jobcluster-c"
        container = {
          name   = "xlnx-jobcluster-c"
          image  = "hpcai.azurecr.io/xlnx-jobcluster-c:latest"
          memory = "0.5Gi"
          cpu    = 0.25
        }
        revisionMode = {
          type = "Single"
        }
      },
      {
        enable = false
        name   = "xwin-jobcluster-c"
        container = {
          name   = "xwin-jobcluster-c"
          image  = "hpcai.azurecr.io/xwin-jobcluster-c:latest"
          memory = "0.5Gi"
          cpu    = 0.25
        }
        revisionMode = {
          type = "Single"
        }
      }
    ]
    zoneRedundancy = {
      enable = false
    }
  },
  {
    enable = false
    name   = "hpcai-c"
    workloadProfiles = [
      {
        enable = true
        name   = "Consumption"
        type   = "Consumption"
        scaleUnit = {
          minCount = 0
          maxCount = 0
        }
      }
    ]
    network = {
      subnetName = "AppCPU"
      internalOnly = {
        enable = true
      }
    }
    apps = [
      {
        enable = false
        name   = "xlnx-jobcluster-c"
        container = {
          name   = "xlnx-jobcluster-c"
          image  = "hpcai.azurecr.io/xlnx-jobcluster-c:latest"
          memory = "0.5Gi"
          cpu    = 0.25
        }
        revisionMode = {
          type = "Single"
        }
      },
      {
        enable = false
        name   = "xwin-jobcluster-c"
        container = {
          name   = "xwin-jobcluster-c"
          image  = "hpcai.azurecr.io/xwin-jobcluster-c:latest"
          memory = "0.5Gi"
          cpu    = 0.25
        }
        revisionMode = {
          type = "Single"
        }
      }
    ]
    zoneRedundancy = {
      enable = false
    }
  },
  {
    enable = false
    name   = "hpcai-g"
    workloadProfiles = [
      {
        enable = true
        name   = "Dedicated"
        type   = "D4"
        scaleUnit = {
          minCount = 0
          maxCount = 1
        }
      }
    ]
    network = {
      subnetName = "AppGPU"
      internalOnly = {
        enable = true
      }
    }
    apps = [
      {
        enable = false
        name   = "xlnx-jobcluster-g"
        container = {
          name   = "xlnx-jobcluster-g"
          image  = "hpcai.azurecr.io/xlnx-jobcluster-g:latest"
          memory = "0.5Gi"
          cpu    = 0.25
        }
        revisionMode = {
          type = "Single"
        }
      },
      {
        enable = false
        name   = "xwin-jobcluster-g"
        container = {
          name   = "xwin-jobcluster-g"
          image  = "hpcai.azurecr.io/xwin-jobcluster-g:latest"
          memory = "0.5Gi"
          cpu    = 0.25
        }
        revisionMode = {
          type = "Single"
        }
      }
    ]
    zoneRedundancy = {
      enable = false
    }
  }
]
