subscriptionId  = "" # REQUIRED
defaultLocation = "SouthCentralUS" # Set from "az account list-locations --query [].name"

#######################################################
# Storage (https://learn.microsoft.com/azure/storage) #
#######################################################

storage = {
  account = {
    type        = "StorageV2" # https://learn.microsoft.com/azure/storage/common/storage-account-overview
    redundancy  = "LRS"       # https://learn.microsoft.com/azure/storage/common/storage-redundancy
    performance = "Standard"  # https://learn.microsoft.com/azure/storage/blobs/storage-blob-performance-tiers
  }
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
}

#############################################################################################################
# Managed Identity (https://learn.microsoft.com/entra/identity/managed-identities-azure-resources/overview) #
#############################################################################################################

managedIdentity = {
  name = "hpcai"
}

############################################################################
# Key Vault (https://learn.microsoft.com/azure/key-vault/general/overview) #
############################################################################

keyVault = {
  name                        = "hpcai"
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
      value = "hpcadmin"
    },
    {
      name  = "AdminPassword"
      value = "P@ssword1234"
    },
    {
      name  = "ServiceUsername"
      value = "hpcservice"
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

######################################################################
# Monitor (https://learn.microsoft.com/azure/azure-monitor/overview) #
######################################################################

monitor = {
  name = "hpcai"
  grafanaDashboard = {
    tier    = "Standard"
    version = 11
    apiKey = {
      enable = false
    }
  }
  applicationInsights = {
    type = "web"
  }
  logAnalytics = {
    workspace = {
      tier = "PerGB2018"
    }
  }
  retentionDays = 90
}

#########################################################################
# Policy (https://learn.microsoft.com/azure/governance/policy/overview) #
#########################################################################

policy = {
  denyPasswordAuthLinux = {
    enable = true
  }
}

##################################################################################################
# Application Configuration (https://learn.microsoft.com/azure/azure-app-configuration/overview) #
##################################################################################################

appConfig = {
  name = "hpcai"
  type = "standard"
}
