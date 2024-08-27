#######################################################
# Storage (https://learn.microsoft.com/azure/storage) #
#######################################################

storage = {
  account = {
    type        = "StorageV2" # https://learn.microsoft.com/azure/storage/common/storage-account-overview
    redundancy  = "LRS"       # https://learn.microsoft.com/azure/storage/common/storage-redundancy
    performance = "Standard"  # https://learn.microsoft.com/azure/storage/blobs/storage-blob-performance-tiers
  }
  security = {
    encryption = {
      infrastructure = {
        enable = true
      }
      service = {
        customKey = {
          enable = false
        }
      }
    }
    httpsTrafficOnly = {
      enable = true
    }
    sharedAccessKey = {
      enable = false
    }
  }
}

############################################################################
# Key Vault (https://learn.microsoft.com/azure/key-vault/general/overview) #
############################################################################

keyVault = {
  type                        = "standard"
  enableForDeployment         = true
  enableForDiskEncryption     = true
  enableForTemplateDeployment = true
  enableTrustedServices       = true
  enablePurgeProtection       = false
  softDeleteRetentionDays     = 90
  secrets = [
    {
      name  = "AdminUsername"
      value = "xadmin"
    },
    {
      name  = "AdminPassword"
      value = "P@ssword1234"
    },
    {
      name  = "ServiceUsername"
      value = "xservice"
    },
    {
      name  = "ServicePassword"
      value = "P@ssword1234"
    },
    {
      name  = "GatewayConnection"
      value = "ConnectionKey"
    }
  ]
  keys = [
    {
      name = "DataEncryption"
      type = "RSA"
      size = 4096
      operations = [
        "decrypt",
        "encrypt",
        "sign",
        "unwrapKey",
        "verify",
        "wrapKey"
      ]
    }
  ]
  certificates = [
  ]
}

##########################################################################################
# App Configuration (https://learn.microsoft.com/azure/azure-app-configuration/overview) #
##########################################################################################

appConfig = {
  tier = "standard"
  localAuth = {
    enable = false
  }
  encryption = {
    enable = false
  }
}

######################################################################
# Monitor (https://learn.microsoft.com/azure/azure-monitor/overview) #
######################################################################

monitor = {
  logWorkspace = {
    tier = "PerGB2018"
  }
  appInsight = {
    type = "web"
  }
  retentionDays = 90
}

######################################################################################################
# Container Registry (https://learn.microsoft.com/azure/container-registry/container-registry-intro) #
######################################################################################################

containerRegistry = {
  enable = false
  name   = "xstudio"
  type   = "Premium"
  adminUser = {
    enable = true
  }
  quarantinePolicy = {
    enable = true
  }
  dataEndpoint = {
    enable = true
  }
  zoneRedundancy = {
    enable = true
  }
  trustPolicy = {
    enable = true
  }
  encryption = {
    enable = false
  }
  retentionPolicy = {
    days = 7
  }
  agentPool = {
    enable        = false
    tier          = "S1"
    instanceCount = 1
  }
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

###################################################################################################
# AI Services      (https://learn.microsoft.com/azure/ai-services/what-are-ai-services)           #
# AI Video Indexer (https://learn.microsoft.com/azure/azure-video-indexer/video-indexer-overview) #
###################################################################################################

aiServices = {
  enable = false
  name   = "xstudio"
  tier   = "S0"
  domain = {
    name = ""
    fqdn = [
    ]
  }
  localAuth = {
    enable = false
  }
  encryption = {
    enable = false
  }
}

####################################################################################
# AI Search (https://learn.microsoft.com/azure/search/search-what-is-azure-search) #
####################################################################################

aiSearch = {
  enable         = false
  name           = "xstudio"
  tier           = "standard"
  hostingMode    = "default"
  replicaCount   = 1
  partitionCount = 1
  localAuth = {
    enable = false
  }
  sharedPrivateAccess = {
    enable = false
  }
}

#################################################################################################################
# Machine Learning (https://learn.microsoft.com/azure/machine-learning/overview-what-is-azure-machine-learning) #
#################################################################################################################

aiMachineLearning = {
  enable = false
  workspace = {
    name = "xstudio"
    type = "Default"
    tier = "Basic"
  }
}

#########################################################################
# Policy (https://learn.microsoft.com/azure/governance/policy/overview) #
#########################################################################

policy = {
  disablePasswordAuthLinux = {
    enable = false
  }
}
