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
    defender = {
      malwareScanning = {
        enable        = true
        maxPerMonthGB = 5000
      }
      sensitiveDataDiscovery = {
        enable = true
      }
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
