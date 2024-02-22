##############################################################################################
# Cosmos DB PostgreSQL (https://learn.microsoft.com/azure/cosmos-db/postgresql/introduction) #
##############################################################################################

variable cosmosPostgreSQL {
  type = object({
    enable       = bool
    name         = string
    version      = string
    versionCitus = string
    worker = object({
      serverEdition = string
      storageMB     = number
      coreCount     = number
      nodeCount     = number
    })
    coordinator = object({
      serverEdition = string
      storageMB     = number
      coreCount     = number
      shards = object({
        enable = bool
      })
    })
    highAvailability = object({
      enable = bool
    })
    maintenanceWindow = object({
      enable      = bool
      dayOfWeek   = number
      startHour   = number
      startMinute = number
    })
  })
}

resource azurerm_private_dns_zone postgre_sql {
  count               = var.cosmosPostgreSQL.enable ? 1 : 0
  name                = "privatelink.postgres.cosmos.azure.com"
  resource_group_name = azurerm_resource_group.database.name
}

resource azurerm_private_dns_zone_virtual_network_link postgre_sql {
  count                 = var.cosmosPostgreSQL.enable ? 1 : 0
  name                  = "postgre-sql"
  resource_group_name   = azurerm_resource_group.database.name
  private_dns_zone_name = azurerm_private_dns_zone.postgre_sql[0].name
  virtual_network_id    = data.azurerm_virtual_network.studio.id
}

resource azurerm_private_endpoint postgre_sql {
  count               = var.cosmosPostgreSQL.enable ? 1 : 0
  name                = "${azurerm_cosmosdb_postgresql_cluster.postgre_sql[0].name}-${azurerm_private_dns_zone_virtual_network_link.postgre_sql[0].name}"
  resource_group_name = azurerm_resource_group.database.name
  location            = azurerm_resource_group.database.location
  subnet_id           = data.azurerm_subnet.farm.id
  private_service_connection {
    name                           = azurerm_cosmosdb_postgresql_cluster.postgre_sql[0].name
    private_connection_resource_id = azurerm_cosmosdb_postgresql_cluster.postgre_sql[0].id
    is_manual_connection           = false
    subresource_names = [
      "coordinator"
    ]
  }
  private_dns_zone_group {
    name = azurerm_cosmosdb_postgresql_cluster.postgre_sql[0].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.postgre_sql[0].id
    ]
  }
  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.postgre_sql
  ]
}

resource azurerm_cosmosdb_postgresql_cluster postgre_sql {
  count                                = var.cosmosPostgreSQL.enable ? 1 : 0
  name                                 = var.cosmosPostgreSQL.name
  resource_group_name                  = azurerm_resource_group.database.name
  location                             = azurerm_resource_group.database.location
  sql_version                          = var.cosmosPostgreSQL.version
  citus_version                        = var.cosmosPostgreSQL.versionCitus
  node_server_edition                  = var.cosmosPostgreSQL.worker.serverEdition
  node_storage_quota_in_mb             = var.cosmosPostgreSQL.worker.storageMB
  node_vcores                          = var.cosmosPostgreSQL.worker.coreCount
  node_count                           = var.cosmosPostgreSQL.worker.nodeCount
  coordinator_server_edition           = var.cosmosPostgreSQL.coordinator.serverEdition
  coordinator_storage_quota_in_mb      = var.cosmosPostgreSQL.coordinator.storageMB
  coordinator_vcore_count              = var.cosmosPostgreSQL.coordinator.coreCount
  shards_on_coordinator_enabled        = var.cosmosPostgreSQL.coordinator.shards.enable
  administrator_login_password         = data.azurerm_key_vault_secret.admin_password.value
  ha_enabled                           = var.cosmosPostgreSQL.highAvailability.enable
  node_public_ip_access_enabled        = false
  coordinator_public_ip_access_enabled = false
  dynamic maintenance_window {
    for_each = var.cosmosPostgreSQL.maintenanceWindow.enable ? [1] : []
    content {
      day_of_week  = var.cosmosPostgreSQL.maintenanceWindow.dayOfWeek
      start_hour   = var.cosmosPostgreSQL.maintenanceWindow.startHour
      start_minute = var.cosmosPostgreSQL.maintenanceWindow.startMinute
    }
  }
}
