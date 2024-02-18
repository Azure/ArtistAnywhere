variable cosmosCassandra {
  type = object({
    enable  = bool
    name    = string
    managedInstance = object({
      enable  = bool
      name    = string
      version = string
    })
  })
}

######################################################################################################
# Cosmos DB Apache Cassandra RU (https://learn.microsoft.com/azure/cosmos-db/cassandra/introduction) #
######################################################################################################

resource azurerm_private_dns_zone cassandra {
  count               = var.cosmosCassandra.enable ? 1 : 0
  name                = "privatelink.cassandra.cosmos.azure.com"
  resource_group_name = azurerm_resource_group.database[0].name
}

resource azurerm_private_dns_zone_virtual_network_link cassandra {
  count                 = var.cosmosCassandra.enable ? 1 : 0
  name                  = "cassandra"
  resource_group_name   = azurerm_resource_group.database[0].name
  private_dns_zone_name = azurerm_private_dns_zone.cassandra[0].name
  virtual_network_id    = data.azurerm_virtual_network.studio.id
}

resource azurerm_private_endpoint cassandra {
  count               = var.cosmosCassandra.enable ? 1 : 0
  name                = "${azurerm_cosmosdb_account.cassandra[0].name}-${azurerm_private_dns_zone_virtual_network_link.cassandra[0].name}"
  resource_group_name = azurerm_resource_group.database[0].name
  location            = azurerm_resource_group.database[0].location
  subnet_id           = data.azurerm_subnet.farm.id
  private_service_connection {
    name                           = azurerm_cosmosdb_account.cassandra[0].name
    private_connection_resource_id = azurerm_cosmosdb_account.cassandra[0].id
    is_manual_connection           = false
    subresource_names = [
      "Cassandra"
    ]
  }
  private_dns_zone_group {
    name = azurerm_cosmosdb_account.cassandra[0].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.cassandra[0].id
    ]
  }
  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.cassandra
  ]
}

resource azurerm_cosmosdb_account cassandra {
  count                      = var.cosmosCassandra.enable ? 1 : 0
  name                       = var.cosmosCassandra.name
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
  capabilities {
    name = "EnableCassandra"
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

########################################################################################################################
# Apache Cassandra Managed Instance (https://learn.microsoft.com/azure/managed-instance-apache-cassandra/introduction) #
########################################################################################################################

resource azurerm_cosmosdb_cassandra_cluster cassandra {
  count                          = var.cosmosCassandra.managedInstance.enable ? 1 : 0
  name                           = var.cosmosCassandra.managedInstance.name
  resource_group_name            = azurerm_resource_group.database[0].name
  location                       = azurerm_resource_group.database[0].location
  version                        = var.cosmosCassandra.managedInstance.version
  default_admin_password         = data.azurerm_key_vault_secret.admin_password.value
  delegated_management_subnet_id = data.azurerm_subnet.data.id
}
