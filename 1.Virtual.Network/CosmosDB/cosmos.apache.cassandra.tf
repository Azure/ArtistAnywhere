variable cosmosCassandra {
  type = object({
    enable = bool
  })
}

variable apacheCassandra {
  type = object({
    enable  = bool
    name    = string
    version = string
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
  name                           = var.apacheCassandra.name
  resource_group_name            = azurerm_resource_group.database.name
  location                       = azurerm_resource_group.database.location
  delegated_management_subnet_id = data.azurerm_subnet.data.id
  version                        = var.apacheCassandra.version
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