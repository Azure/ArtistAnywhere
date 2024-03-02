##############################################################################################
# Cosmos DB PostgreSQL (https://learn.microsoft.com/azure/cosmos-db/postgresql/introduction) #
##############################################################################################

variable cosmosPostgreSQL {
  type = object({
    enable = bool
    cluster = object({
      name         = string
      version      = string
      versionCitus = string
      firewallRules = list(object({
        enable       = bool
        startAddress = string
        endAddress   = string
      }))
    })
    node = object({
      serverEdition = string
      storageMB     = number
      coreCount     = number
      count         = number
      configuration = map(string)
    })
    coordinator = object({
      serverEdition = string
      storageMB     = number
      coreCount     = number
      configuration = map(string)
      shards = object({
        enable = bool
      })
    })
    roles = list(object({
      enable   = bool
      name     = string
      password = string
    }))
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
  resource_group_name   = azurerm_private_dns_zone.postgre_sql[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.postgre_sql[0].name
  virtual_network_id    = data.azurerm_virtual_network.studio.id
}

resource azurerm_private_endpoint postgre_sql {
  count               = var.cosmosPostgreSQL.enable ? 1 : 0
  name                = "${azurerm_cosmosdb_postgresql_cluster.postgre_sql[0].name}-${azurerm_private_dns_zone_virtual_network_link.postgre_sql[0].name}"
  resource_group_name = azurerm_resource_group.database.name
  location            = azurerm_resource_group.database.location
  subnet_id           = data.azurerm_subnet.data.id
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
  name                                 = var.cosmosPostgreSQL.cluster.name
  resource_group_name                  = azurerm_resource_group.database.name
  location                             = azurerm_resource_group.database.location
  sql_version                          = var.cosmosPostgreSQL.cluster.version
  citus_version                        = var.cosmosPostgreSQL.cluster.versionCitus
  node_server_edition                  = var.cosmosPostgreSQL.node.serverEdition
  node_storage_quota_in_mb             = var.cosmosPostgreSQL.node.storageMB
  node_vcores                          = var.cosmosPostgreSQL.node.coreCount
  node_count                           = var.cosmosPostgreSQL.node.count
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

resource azurerm_cosmosdb_postgresql_firewall_rule postgre_sql {
  for_each = {
    for firewallRule in var.cosmosPostgreSQL.cluster.firewallRules : firewallRule.name => firewallRule if var.cosmosPostgreSQL.enable && firewallRule.enable
  }
  name             = each.value.name
  start_ip_address = each.value.startAddress
  end_ip_address   = each.value.endAddress
  cluster_id       = azurerm_cosmosdb_postgresql_cluster.postgre_sql[0].id
}

resource azurerm_cosmosdb_postgresql_node_configuration postgre_sql {
  for_each   = var.cosmosPostgreSQL.enable ? var.cosmosPostgreSQL.node.configuration : {}
  name       = each.key
  value      = each.value
  cluster_id = azurerm_cosmosdb_postgresql_cluster.postgre_sql[0].id
}

resource azurerm_cosmosdb_postgresql_coordinator_configuration postgre_sql {
  for_each   = var.cosmosPostgreSQL.enable ? var.cosmosPostgreSQL.coordinator.configuration : {}
  name       = each.key
  value      = each.value
  cluster_id = azurerm_cosmosdb_postgresql_cluster.postgre_sql[0].id
}

resource azurerm_cosmosdb_postgresql_role postgre_sql {
  for_each = {
    for role in var.cosmosPostgreSQL.roles : role.name => role if var.cosmosPostgreSQL.enable && role.enable
  }
  name       = each.value.name
  password   = each.value.password
  cluster_id = azurerm_cosmosdb_postgresql_cluster.postgre_sql[0].id
}
