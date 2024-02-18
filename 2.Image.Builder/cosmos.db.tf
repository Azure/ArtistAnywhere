########################################################################
# Cosmos DB (https://learn.microsoft.com/azure/cosmos-db/introduction) #
########################################################################

variable cosmosDB {
  type = object({
    tier = string
    consistency = object({
      policyLevel        = string
      maxIntervalSeconds = number
      maxStalenessPrefix = number
    })
    customEncryption = object({
      enable  = bool
      keyName = string
    })
    partitionMerge = object({
      enable = bool
    })
    aggregationPipeline = object({
      enable = bool
    })
    automaticFailover = object({
      enable = bool
    })
    analytics = object({
      enable     = bool
      schemaType = string
    })
  })
}

data azurerm_key_vault_key data_encryption {
  count        = var.cosmosDB.customEncryption.enable ? 1 : 0
  name         = var.cosmosDB.customEncryption.keyName != "" ? var.cosmosDB.customEncryption.keyName : module.global.keyVault.keyName.dataEncryption
  key_vault_id = data.azurerm_key_vault.studio.id
}

locals {
  azurePortalAddresses = "104.42.195.92,40.76.54.131,52.176.6.30,52.169.50.45,52.187.184.26"
}
