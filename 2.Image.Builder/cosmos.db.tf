########################################################################
# Cosmos DB (https://learn.microsoft.com/azure/cosmos-db/introduction) #
########################################################################

variable cosmosDB {
  type = object({
    enable     = bool
    name       = string
    tier       = string
    version    = string
    nodeCount  = number
    diskSizeGB = number
    highAvailability = object({
      enable = bool
    })
  })
}

# data azurerm_key_vault_key data_encryption {
#   count        = var.cosmosDB.enable ? 1 : 0
#   name         = module.global.keyVault.keyName.dataEncryption
#   key_vault_id = data.azurerm_key_vault.studio.id
# }

resource azapi_resource mongo_cluster {
  count     = var.cosmosDB.enable ? 1 : 0
  name      = var.cosmosDB.name
  type      = "Microsoft.DocumentDB/mongoClusters@2023-11-15-preview"
  parent_id = azurerm_resource_group.database.id
  location  = azurerm_resource_group.database.location
  body = jsonencode({
    properties = {
      nodeGroupSpecs = [
        {
          kind       = "Shard"
          sku        = var.cosmosDB.tier
          nodeCount  = var.cosmosDB.nodeCount
          diskSizeGB = var.cosmosDB.diskSizeGB
          enableHa   = var.cosmosDB.highAvailability.enable
        }
      ]
      serverVersion              = var.cosmosDB.version
      administratorLogin         = data.azurerm_key_vault_secret.admin_username.value
      administratorLoginPassword = data.azurerm_key_vault_secret.admin_password.value
    }
  })
}
