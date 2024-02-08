########################################################################
# Cosmos DB (https://learn.microsoft.com/azure/cosmos-db/introduction) #
########################################################################

variable cosmosDB {
  type = object({
    enable = bool
    account = object({
      name             = string
      type             = string
      offerType        = string
      consistencyLevel = string
    })
    database = object({
      name       = string
      throughput = number
    })
  })
}

resource azurerm_cosmosdb_account scheduler {
  count               = var.cosmosDB.enable ? 1 : 0
  name                = var.cosmosDB.account.name
  resource_group_name = azurerm_resource_group.database.name
  location            = azurerm_resource_group.database.location
  offer_type          = var.cosmosDB.account.offerType
  kind                = var.cosmosDB.account.type
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  consistency_policy {
    consistency_level = var.cosmosDB.account.consistencyLevel
  }
  geo_location {
    location          = azurerm_resource_group.database.location
    failover_priority = 0
  }
  capabilities {
    name = "EnableMongo"
  }
}

resource azurerm_cosmosdb_mongo_database scheduler {
  count               = var.cosmosDB.enable ? 1 : 0
  name                = var.cosmosDB.database.name
  resource_group_name = azurerm_resource_group.database.name
  account_name        = azurerm_cosmosdb_account.scheduler[0].name
  throughput          = var.cosmosDB.database.throughput
}
