########################################################################
# Cosmos DB NoSQL (https://learn.microsoft.com/azure/cosmos-db/nosql/) #
########################################################################

variable cosmosNoSQL {
  type = object({
    enable = bool
    name   = string
    dedicatedGateway = object({
      enable = bool
      size   = string
      count  = number
    })
  })
}

resource azurerm_private_dns_zone no_sql {
  count               = var.cosmosNoSQL.enable ? 1 : 0
  name                = var.cosmosNoSQL.dedicatedGateway.enable ? "privatelink.sqlx.cosmos.azure.com" : "privatelink.documents.azure.com"
  resource_group_name = azurerm_resource_group.database[0].name
}

resource azurerm_private_dns_zone_virtual_network_link no_sql {
  count                 = var.cosmosNoSQL.enable ? 1 : 0
  name                  = "no-sql"
  resource_group_name   = azurerm_resource_group.database[0].name
  private_dns_zone_name = azurerm_private_dns_zone.no_sql[0].name
  virtual_network_id    = data.azurerm_virtual_network.studio.id
}

resource azurerm_private_endpoint no_sql {
  count               = var.cosmosNoSQL.enable ? 1 : 0
  name                = "${azurerm_cosmosdb_account.no_sql[0].name}-${azurerm_private_dns_zone_virtual_network_link.no_sql[0].name}"
  resource_group_name = azurerm_resource_group.database[0].name
  location            = azurerm_resource_group.database[0].location
  subnet_id           = data.azurerm_subnet.farm.id
  private_service_connection {
    name                           = azurerm_cosmosdb_account.no_sql[0].name
    private_connection_resource_id = azurerm_cosmosdb_account.no_sql[0].id
    is_manual_connection           = false
    subresource_names = [
      var.cosmosNoSQL.dedicatedGateway.enable ? "SqlDedicated" : "Sql"
    ]
  }
  private_dns_zone_group {
    name = azurerm_cosmosdb_account.no_sql[0].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.no_sql[0].id
    ]
  }
  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.no_sql
  ]
}

resource azurerm_cosmosdb_account no_sql {
  count                      = var.cosmosNoSQL.enable ? 1 : 0
  name                       = var.cosmosNoSQL.name
  resource_group_name        = azurerm_resource_group.database[0].name
  location                   = azurerm_resource_group.database[0].location
  offer_type                 = var.cosmosDB.tier
  partition_merge_enabled    = var.cosmosDB.partitionMerge.enable
  enable_automatic_failover  = var.cosmosDB.automaticFailover.enable
  key_vault_key_id           = var.cosmosDB.customEncryption.enable ? data.azurerm_key_vault_key.data_encryption[0].versionless_id : null
  analytical_storage_enabled = var.cosmosDB.analytics.enable
  ip_range_filter            = local.azurePortalAddresses
  default_identity_type      = "UserAssignedIdentity=${data.azurerm_user_assigned_identity.studio.id}"
  kind                       = "GlobalDocumentDB"
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  consistency_policy {
    consistency_level       = var.cosmosDB.consistency.policyLevel
    max_interval_in_seconds = var.cosmosDB.consistency.maxIntervalSeconds
    max_staleness_prefix    = var.cosmosDB.consistency.maxStalenessPrefix
  }
  analytical_storage {
    schema_type = var.cosmosDB.analytics.schemaType
  }
  dynamic geo_location {
    for_each = local.regionNames
    content {
      location          = geo_location.value
      failover_priority = index(local.regionNames, geo_location.value)
    }
  }
}

resource azurerm_cosmosdb_sql_dedicated_gateway no_sql {
  count               = var.cosmosNoSQL.enable && var.cosmosNoSQL.dedicatedGateway.enable ? 1 : 0
  cosmosdb_account_id = azurerm_cosmosdb_account.no_sql[0].id
  instance_size       = var.cosmosNoSQL.dedicatedGateway.size
  instance_count      = var.cosmosNoSQL.dedicatedGateway.count
}
