#######################################################
# Storage (https://learn.microsoft.com/azure/storage) #
#######################################################

rootStorage = {
  accountType        = "StorageV2" # https://learn.microsoft.com/azure/storage/common/storage-account-overview
  accountRedundancy  = "LRS"       # https://learn.microsoft.com/azure/storage/common/storage-redundancy
  accountPerformance = "Standard"  # https://learn.microsoft.com/azure/storage/blobs/storage-blob-performance-tiers
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
