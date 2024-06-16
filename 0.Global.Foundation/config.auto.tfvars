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
  logWorkspace = {
    tier = "PerGB2018"
  }
  appInsight = {
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
