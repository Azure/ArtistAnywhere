######################################################################################################
# Cosmos DB PostgreSQL       (https://learn.microsoft.com/azure/cosmos-db/postgresql/introduction)   #
# PostgreSQL Flexible Server (https://learn.microsoft.com/azure/postgresql/flexible-server/overview) #
######################################################################################################

variable postgreSQL {
  type = object({
    enable  = bool
    name    = string
    version = string
    server = object({
      enable    = bool
      type      = string
      storageMB = number
    })
    cluster = object({
      citus = object({
        version = string
      })
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
    adminLogin = object({
      userName     = string
      userPassword = string
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

resource azurerm_postgresql_flexible_server studio {
  count                  = var.postgreSQL.server.enable ? 1 : 0
  name                   = var.postgreSQL.name
  resource_group_name    = azurerm_resource_group.data.name
  location               = azurerm_resource_group.data.location
  version                = var.postgreSQL.version
  sku_name               = var.postgreSQL.server.type
  administrator_login    = var.postgreSQL.adminLogin.userName != "" ? var.postgreSQL.adminLogin.userName : data.azurerm_key_vault_secret.admin_username.value
  administrator_password = var.postgreSQL.adminLogin.userPassword != "" ? var.postgreSQL.adminLogin.userPassword : data.azurerm_key_vault_secret.admin_password.value
  delegated_subnet_id    = data.azurerm_subnet.data_postgre_sql.id
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
}

# resource "azurerm_postgresql_flexible_server" "example" {
#   delegated_subnet_id           = azurerm_subnet.example.id
#   private_dns_zone_id           = azurerm_private_dns_zone.example.id
# }

resource azurerm_cosmosdb_postgresql_cluster studio {
  count                                = var.postgreSQL.enable ? 1 : 0
  name                                 = var.postgreSQL.name
  resource_group_name                  = azurerm_resource_group.data.name
  location                             = azurerm_resource_group.data.location
  sql_version                          = var.postgreSQL.version
  citus_version                        = var.postgreSQL.cluster.citus.version
  node_server_edition                  = var.postgreSQL.node.serverEdition
  node_storage_quota_in_mb             = var.postgreSQL.node.storageMB
  node_vcores                          = var.postgreSQL.node.coreCount
  node_count                           = var.postgreSQL.node.count
  coordinator_server_edition           = var.postgreSQL.coordinator.serverEdition
  coordinator_storage_quota_in_mb      = var.postgreSQL.coordinator.storageMB
  coordinator_vcore_count              = var.postgreSQL.coordinator.coreCount
  shards_on_coordinator_enabled        = var.postgreSQL.coordinator.shards.enable
  administrator_login_password         = var.postgreSQL.adminLogin.userPassword != "" ? var.postgreSQL.adminLogin.userPassword : data.azurerm_key_vault_secret.admin_password.value
  ha_enabled                           = var.postgreSQL.highAvailability.enable
  node_public_ip_access_enabled        = false
  coordinator_public_ip_access_enabled = false
  dynamic maintenance_window {
    for_each = var.postgreSQL.maintenanceWindow.enable ? [1] : []
    content {
      day_of_week  = var.postgreSQL.maintenanceWindow.dayOfWeek
      start_hour   = var.postgreSQL.maintenanceWindow.startHour
      start_minute = var.postgreSQL.maintenanceWindow.startMinute
    }
  }
}

resource azurerm_cosmosdb_postgresql_firewall_rule studio {
  for_each = {
    for firewallRule in var.postgreSQL.cluster.firewallRules : firewallRule.name => firewallRule if var.postgreSQL.enable && firewallRule.enable
  }
  name             = each.value.name
  start_ip_address = each.value.startAddress
  end_ip_address   = each.value.endAddress
  cluster_id       = azurerm_cosmosdb_postgresql_cluster.studio[0].id
}

resource azurerm_cosmosdb_postgresql_node_configuration postgre_sql {
  for_each   = var.postgreSQL.enable ? var.postgreSQL.node.configuration : {}
  name       = each.key
  value      = each.value
  cluster_id = azurerm_cosmosdb_postgresql_cluster.studio[0].id
}

resource azurerm_cosmosdb_postgresql_coordinator_configuration postgre_sql {
  for_each   = var.postgreSQL.enable ? var.postgreSQL.coordinator.configuration : {}
  name       = each.key
  value      = each.value
  cluster_id = azurerm_cosmosdb_postgresql_cluster.studio[0].id
}

resource azurerm_cosmosdb_postgresql_role postgre_sql {
  for_each = {
    for role in var.postgreSQL.roles : role.name => role if var.postgreSQL.enable && role.enable
  }
  name       = each.value.name
  password   = each.value.password
  cluster_id = azurerm_cosmosdb_postgresql_cluster.studio[0].id
}

resource azurerm_private_dns_zone postgre_sql {
  count               = var.postgreSQL.enable ? 1 : 0
  name                = "privatelink.postgres.cosmos.azure.com"
  resource_group_name = azurerm_cosmosdb_postgresql_cluster.studio[0].resource_group_name
}

resource azurerm_private_dns_zone_virtual_network_link postgre_sql {
  count                 = var.postgreSQL.enable ? 1 : 0
  name                  = "postgre-sql"
  resource_group_name   = azurerm_private_dns_zone.postgre_sql[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.postgre_sql[0].name
  virtual_network_id    = data.azurerm_virtual_network.studio_region.id
}

resource azurerm_private_endpoint postgre_sql {
  count               = var.postgreSQL.enable ? 1 : 0
  name                = "${azurerm_cosmosdb_postgresql_cluster.studio[0].name}-${azurerm_private_dns_zone_virtual_network_link.postgre_sql[0].name}"
  resource_group_name = azurerm_cosmosdb_postgresql_cluster.studio[0].resource_group_name
  location            = azurerm_cosmosdb_postgresql_cluster.studio[0].location
  subnet_id           = data.azurerm_subnet.data.id
  private_service_connection {
    name                           = azurerm_cosmosdb_postgresql_cluster.studio[0].name
    private_connection_resource_id = azurerm_cosmosdb_postgresql_cluster.studio[0].id
    is_manual_connection           = false
    subresource_names = [
      "coordinator"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.postgre_sql[0].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.postgre_sql[0].id
    ]
  }
}
