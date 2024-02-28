variable cosmosCassandra {
  type = object({
    enable = bool
    account = object({
      name = string
    })
    database = object({
      enable     = bool
      name       = string
      throughput = number
      tables = list(object({
        enable     = bool
        name       = string
        throughput = number
        schema = object({
          partitionKeys = list(object({
            enable = bool
            name   = string
          }))
          clusterKeys = list(object({
            enable  = bool
            name    = string
            orderBy = string
          }))
          columns = list(object({
            enable = bool
            name   = string
            type   = string
          }))
        })
      }))
    })
  })
}

variable apacheCassandra {
  type = object({
    enable = bool
    cluster = object({
      name    = string
      version = string
    })
    datacenter = object({
      name = string
      node = object({
        type  = string
        count = number
        disk = object({
          type  = string
          count = number
        })
      })
    })
    backup = object({
      intervalHours = number
    })
  })
}

###################################################################################################
# Cosmos DB Apache Cassandra (https://learn.microsoft.com/azure/cosmos-db/cassandra/introduction) #
###################################################################################################

resource azurerm_private_dns_zone cassandra {
  count               = var.cosmosCassandra.enable ? 1 : 0
  name                = "privatelink.cassandra.cosmos.azure.com"
  resource_group_name = azurerm_resource_group.database.name
}

resource azurerm_private_dns_zone_virtual_network_link cassandra {
  count                 = var.cosmosCassandra.enable ? 1 : 0
  name                  = "cassandra"
  resource_group_name   = azurerm_resource_group.database.name
  private_dns_zone_name = azurerm_private_dns_zone.cassandra[0].name
  virtual_network_id    = data.azurerm_virtual_network.studio.id
}

resource azurerm_private_endpoint cassandra {
  count               = var.cosmosCassandra.enable ? 1 : 0
  name                = azurerm_cosmosdb_account.studio["cassandra"].name
  resource_group_name = azurerm_resource_group.database.name
  location            = azurerm_resource_group.database.location
  subnet_id           = data.azurerm_subnet.farm.id
  private_service_connection {
    name                           = azurerm_cosmosdb_account.studio["cassandra"].name
    private_connection_resource_id = azurerm_cosmosdb_account.studio["cassandra"].id
    is_manual_connection           = false
    subresource_names = [
      "Cassandra"
    ]
  }
  private_dns_zone_group {
    name = azurerm_cosmosdb_account.studio["cassandra"].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.cassandra[0].id
    ]
  }
  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.cassandra
  ]
}

resource azurerm_cosmosdb_cassandra_keyspace cassandra {
  count               = var.cosmosCassandra.enable && var.cosmosCassandra.database.enable ? 1 : 0
  name                = var.cosmosCassandra.database.name
  resource_group_name = azurerm_cosmosdb_account.studio["cassandra"].resource_group_name
  account_name        = azurerm_cosmosdb_account.studio["cassandra"].name
  throughput          = var.cosmosCassandra.database.throughput
}

resource azurerm_cosmosdb_cassandra_table cassandra {
  for_each = {
    for table in var.cosmosCassandra.database.tables : table.name => table if var.cosmosCassandra.enable && var.cosmosCassandra.database.enable && table.enable
  }
  name                  = each.value.name
  cassandra_keyspace_id = azurerm_cosmosdb_cassandra_keyspace.cassandra[0].id
  schema {
    dynamic partition_key {
      for_each = {
        for partitionKey in each.value.schema.partitionKeys : partitionKey.name => partitionKey if partitionKey.enable
      }
      content {
        name = partition_key.value["name"]
      }
    }
    dynamic cluster_key {
      for_each = {
        for clusterKey in each.value.schema.clusterKeys : clusterKey.name => clusterKey if clusterKey.enable
      }
      content {
        name     = cluster_key.value["name"]
        order_by = cluster_key.value["orderBy"]
      }
    }
    dynamic column {
      for_each = {
        for column in each.value.schema.columns : column.name => column if column.enable
      }
      content {
        name = column.value["name"]
        type = column.value["type"]
      }
    }
  }
}

########################################################################################################################
# Apache Cassandra Managed Instance (https://learn.microsoft.com/azure/managed-instance-apache-cassandra/introduction) #
########################################################################################################################

resource azurerm_role_assignment cassandra {
  count                = var.apacheCassandra.enable ? 1 : 0
  role_definition_name = "Network Contributor" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#network-contributor
  principal_id         = data.azuread_service_principal.cosmos_db.object_id
  scope                = data.azurerm_virtual_network.studio.id
}

resource azurerm_cosmosdb_cassandra_cluster cassandra {
  count                          = var.apacheCassandra.enable ? 1 : 0
  name                           = var.apacheCassandra.cluster.name
  resource_group_name            = azurerm_resource_group.database.name
  location                       = azurerm_resource_group.database.location
  delegated_management_subnet_id = data.azurerm_subnet.data.id
  version                        = var.apacheCassandra.cluster.version
  hours_between_backups          = var.apacheCassandra.backup.intervalHours
  default_admin_password         = data.azurerm_key_vault_secret.admin_password.value
  identity {
    type = "SystemAssigned"
  }
  depends_on = [
    azurerm_role_assignment.cassandra
  ]
}

resource azurerm_cosmosdb_cassandra_datacenter cassandra {
  count                          = var.apacheCassandra.enable ? 1 : 0
  name                           = var.apacheCassandra.datacenter.name
  location                       = azurerm_cosmosdb_cassandra_cluster.cassandra[0].location
  cassandra_cluster_id           = azurerm_cosmosdb_cassandra_cluster.cassandra[0].id
  delegated_management_subnet_id = data.azurerm_subnet.data.id
  sku_name                       = var.apacheCassandra.datacenter.node.type
  node_count                     = var.apacheCassandra.datacenter.node.count
  disk_sku                       = var.apacheCassandra.datacenter.node.disk.type
  disk_count                     = var.apacheCassandra.datacenter.node.disk.count
}
