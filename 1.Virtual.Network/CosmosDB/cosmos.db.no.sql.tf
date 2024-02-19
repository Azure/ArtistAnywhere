########################################################################
# Cosmos DB NoSQL (https://learn.microsoft.com/azure/cosmos-db/nosql/) #
########################################################################

variable cosmosNoSQL {
  type = object({
    enable = bool
    gateway = object({
      enable = bool
      size   = string
      count  = number
    })
    database = object({
      name       = string
      throughput = number
    })
  })
}

resource azurerm_private_dns_zone no_sql {
  count               = var.cosmosNoSQL.enable || var.cosmosGremlin.enable || var.cosmosTable.enable ? 1 : 0
  name                = var.cosmosNoSQL.gateway.enable ? "privatelink.sqlx.cosmos.azure.com" : "privatelink.documents.azure.com"
  resource_group_name = azurerm_resource_group.database.name
}

resource azurerm_private_dns_zone_virtual_network_link no_sql {
  count                 = var.cosmosNoSQL.enable || var.cosmosGremlin.enable || var.cosmosTable.enable ? 1 : 0
  name                  = "no-sql"
  resource_group_name   = azurerm_resource_group.database.name
  private_dns_zone_name = azurerm_private_dns_zone.no_sql[0].name
  virtual_network_id    = data.azurerm_virtual_network.studio.id
}

resource azurerm_private_endpoint no_sql {
  count               = var.cosmosNoSQL.enable ? 1 : 0
  name                = azurerm_cosmosdb_account.studio["sql"].name
  resource_group_name = azurerm_resource_group.database.name
  location            = azurerm_resource_group.database.location
  subnet_id           = data.azurerm_subnet.farm.id
  private_service_connection {
    name                           = azurerm_cosmosdb_account.studio["sql"].name
    private_connection_resource_id = azurerm_cosmosdb_account.studio["sql"].id
    is_manual_connection           = false
    subresource_names = [
      var.cosmosNoSQL.gateway.enable ? "SqlDedicated" : "Sql"
    ]
  }
  private_dns_zone_group {
    name = azurerm_cosmosdb_account.studio["sql"].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.no_sql[0].id
    ]
  }
  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.no_sql
  ]
}

resource azurerm_cosmosdb_sql_dedicated_gateway no_sql {
  count               = var.cosmosNoSQL.enable && var.cosmosNoSQL.gateway.enable ? 1 : 0
  cosmosdb_account_id = azurerm_cosmosdb_account.studio["sql"].id
  instance_size       = var.cosmosNoSQL.gateway.size
  instance_count      = var.cosmosNoSQL.gateway.count
}

resource azurerm_cosmosdb_sql_database no_sql {
  count               = var.cosmosNoSQL.enable && var.cosmosNoSQL.database.name != "" ? 1 : 0
  name                = var.cosmosNoSQL.database.name
  resource_group_name = azurerm_resource_group.database.name
  account_name        = azurerm_cosmosdb_account.studio["sql"].name
  throughput          = var.cosmosDB.serverless.enable ? null : var.cosmosNoSQL.database.throughput
}
