#######################################################
# Storage (https://learn.microsoft.com/azure/storage) #
#######################################################

storage = {
  accountType        = "StorageV2" # https://learn.microsoft.com/azure/storage/common/storage-account-overview
  accountRedundancy  = "LRS"       # https://learn.microsoft.com/azure/storage/common/storage-redundancy
  accountPerformance = "Standard"  # https://learn.microsoft.com/azure/storage/blobs/storage-blob-performance-tiers
}

######################################################################
# Monitor (https://learn.microsoft.com/azure/azure-monitor/overview) #
######################################################################

monitor = {
  workspace = {
    sku = "PerGB2018"
  }
  insight = {
    type = "web"
  }
  retentionDays = 90
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
      name  = "DatabaseUsername"
      value = "dbuser"
    },
    {
      name  = "DatabasePassword"
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
      size = 3072
      operations = [
        "decrypt",
        "encrypt",
        "sign",
        "unwrapKey",
        "verify",
        "wrapKey"
      ]
    },
    {
      name = "CacheEncryption"
      type = "RSA"
      size = 3072
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
  encryption = {
    enable = false
  }
}

################################################################################################
# Traffic Manager (https://learn.microsoft.com/azure/traffic-manager/traffic-manager-overview) #
################################################################################################

trafficManager = {
  routingMethod = "Performance" # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/traffic_manager_profile.html#traffic_routing_method
  dns = {
    name = "xstudio"
    ttl  = 300
  }
  monitor = {
    protocol = "HTTP"
    port     = 80
    path     = "/"
  }
  trafficView = {
    enable = true
  }
}

####################################################################################
# AI Services (https://learn.microsoft.com/azure/ai-services/what-are-ai-services) #
####################################################################################

ai = {
  video = {
    enable = true
    name   = "xstudio"
  }
  open = {
    enable     = false
    name       = "xstudio-open"
    tier       = "S0"
    domainName = ""
  }
  cognitive = {
    enable     = true
    name       = "xstudio"
    tier       = "S0"
    domainName = ""
  }
  speech = {
    enable     = true
    name       = "xstudio-speech"
    tier       = "S0"
    domainName = ""
  }
  language = {
    conversational = {
      enable     = true
      name       = "xstudio-language-conversational"
      tier       = "S"
      domainName = ""
    }
    textAnalytics = {
      enable     = true
      name       = "xstudio-text-analytics"
      tier       = "S"
      domainName = ""
    }
    textTranslation = {
      enable     = true
      name       = "xstudio-text-translation"
      tier       = "S1"
      domainName = ""
    }
  }
  vision = {
    enable     = true
    name       = "xstudio-vision"
    tier       = "S1"
    domainName = ""
    training = {
      enable     = true
      name       = "xstudio-vision-training"
      tier       = "S0"
      domainName = ""
    }
    prediction = {
      enable     = true
      name       = "xstudio-vision-prediction"
      tier       = "S0"
      domainName = ""
    }
  }
  face = {
    enable     = true
    name       = "xstudio-face"
    tier       = "S0"
    domainName = ""
  }
  document = {
    enable     = true
    name       = "xstudio-document"
    tier       = "S0"
    domainName = ""
  }
  search = {
    enable         = false
    name           = "xstudio"
    tier           = "standard"
    hostingMode    = "default"
    replicaCount   = 1
    partitionCount = 1
    sharedPrivateAccess = {
      enable = false
    }
  }
  machineLearning = {
    enable = false
    workspace = {
      name = "xstudio"
      tier = "Default"
    }
  }
  encryption = {
    enable = false
  }
}
