###############################################################################################
# Cosmos DB Apache Gremlin (https://learn.microsoft.com/azure/cosmos-db/gremlin/introduction) #
###############################################################################################

variable cosmosGremlin {
  type = object({
    enable = bool
    account = object({
      name = string
    })
    database = object({
      enable     = bool
      name       = string
      throughput = number
      graphs = list(object({
        enable     = bool
        name       = string
        throughput = number
        partitionKey = object({
          path    = string
          version = number
        })
      }))
    })
  })
}

resource azurerm_private_dns_zone gremlin {
  count               = var.cosmosGremlin.enable ? 1 : 0
  name                = "privatelink.gremlin.cosmos.azure.com"
  resource_group_name = azurerm_resource_group.database.name
}

resource azurerm_private_dns_zone_virtual_network_link gremlin {
  count                 = var.cosmosGremlin.enable ? 1 : 0
  name                  = "gremlin"
  resource_group_name   = azurerm_private_dns_zone.gremlin[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.gremlin[0].name
  virtual_network_id    = data.azurerm_virtual_network.studio.id
}

resource azurerm_private_endpoint gremlin {
  count               = var.cosmosGremlin.enable ? 1 : 0
  name                = azurerm_cosmosdb_account.studio["gremlin"].name
  resource_group_name = azurerm_resource_group.database.name
  location            = azurerm_resource_group.database.location
  subnet_id           = data.azurerm_subnet.data.id
  private_service_connection {
    name                           = azurerm_cosmosdb_account.studio["gremlin"].name
    private_connection_resource_id = azurerm_cosmosdb_account.studio["gremlin"].id
    is_manual_connection           = false
    subresource_names = [
      "Gremlin"
    ]
  }
  private_dns_zone_group {
    name = azurerm_cosmosdb_account.studio["gremlin"].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.gremlin[0].id
    ]
  }
  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.gremlin
  ]
}

resource azurerm_private_endpoint gremlin_sql {
  count               = var.cosmosGremlin.enable ? 1 : 0
  name                = "${azurerm_cosmosdb_account.studio["gremlin"].name}-sql"
  resource_group_name = azurerm_resource_group.database.name
  location            = azurerm_resource_group.database.location
  subnet_id           = data.azurerm_subnet.data.id
  private_service_connection {
    name                           = azurerm_cosmosdb_account.studio["gremlin"].name
    private_connection_resource_id = azurerm_cosmosdb_account.studio["gremlin"].id
    is_manual_connection           = false
    subresource_names = [
      "Sql"
    ]
  }
  private_dns_zone_group {
    name = azurerm_cosmosdb_account.studio["gremlin"].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.no_sql[0].id
    ]
  }
  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.no_sql
  ]
}

resource azurerm_cosmosdb_gremlin_database gremlin {
  count               = var.cosmosGremlin.enable && var.cosmosGremlin.database.enable ? 1 : 0
  name                = var.cosmosGremlin.database.name
  resource_group_name = azurerm_cosmosdb_account.studio["gremlin"].resource_group_name
  account_name        = azurerm_cosmosdb_account.studio["gremlin"].name
  throughput          = var.cosmosGremlin.database.throughput
}

resource azurerm_cosmosdb_gremlin_graph gremlin {
  for_each = {
    for graph in var.cosmosGremlin.database.graphs : graph.name => graph if var.cosmosGremlin.enable && var.cosmosGremlin.database.enable && graph.enable
  }
  name                  = each.value.name
  resource_group_name   = azurerm_cosmosdb_gremlin_database.gremlin[0].resource_group_name
  account_name          = azurerm_cosmosdb_gremlin_database.gremlin[0].account_name
  database_name         = azurerm_cosmosdb_gremlin_database.gremlin[0].name
  throughput            = each.value.throughput
  partition_key_path    = each.value.partitionKey.path
  partition_key_version = each.value.partitionKey.version
}
