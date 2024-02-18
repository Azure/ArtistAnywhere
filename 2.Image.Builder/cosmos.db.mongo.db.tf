#########################################################################################
# Cosmos DB Mongo DB (https://learn.microsoft.com/azure/cosmos-db/mongodb/introduction) #
#########################################################################################

variable cosmosMongoDB {
  type = object({
    enable  = bool
    name    = string
    version = string
    database = object({
      name       = string
      throughput = number
    })
    vCore = object({
      enable     = bool
      name       = string
      tier       = string
      version    = string
      nodeCount  = number
      diskSizeGB = number
      highAvailability = object({
        enable = bool
      })
    })
  })
}

###############################################################################################
# Cosmos DB Mongo DB RU (https://learn.microsoft.com/azure/cosmos-db/mongodb/ru/introduction) #
###############################################################################################

resource azurerm_private_dns_zone mongo_db {
  count               = var.cosmosMongoDB.enable ? 1 : 0
  name                = "privatelink.mongo.cosmos.azure.com"
  resource_group_name = azurerm_resource_group.database[0].name
}

resource azurerm_private_dns_zone_virtual_network_link mongo_db {
  count                 = var.cosmosMongoDB.enable ? 1 : 0
  name                  = "mongo"
  resource_group_name   = azurerm_resource_group.database[0].name
  private_dns_zone_name = azurerm_private_dns_zone.mongo_db[0].name
  virtual_network_id    = data.azurerm_virtual_network.studio.id
}

resource azurerm_private_endpoint mongo_db {
  count               = var.cosmosMongoDB.enable ? 1 : 0
  name                = "${azurerm_cosmosdb_account.mongo_db[0].name}-${azurerm_private_dns_zone_virtual_network_link.mongo_db[0].name}"
  resource_group_name = azurerm_resource_group.database[0].name
  location            = azurerm_resource_group.database[0].location
  subnet_id           = data.azurerm_subnet.farm.id
  private_service_connection {
    name                           = azurerm_cosmosdb_account.mongo_db[0].name
    private_connection_resource_id = azurerm_cosmosdb_account.mongo_db[0].id
    is_manual_connection           = false
    subresource_names = [
      "MongoDB"
    ]
  }
  private_dns_zone_group {
    name = azurerm_cosmosdb_account.mongo_db[0].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.mongo_db[0].id
    ]
  }
  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.mongo_db
  ]
}

resource azurerm_cosmosdb_account mongo_db {
  count                      = var.cosmosMongoDB.enable ? 1 : 0
  name                       = var.cosmosMongoDB.name
  resource_group_name        = azurerm_resource_group.database[0].name
  location                   = azurerm_resource_group.database[0].location
  offer_type                 = var.cosmosDB.tier
  partition_merge_enabled    = var.cosmosDB.partitionMerge.enable
  enable_automatic_failover  = var.cosmosDB.automaticFailover.enable
  key_vault_key_id           = var.cosmosDB.customEncryption.enable ? data.azurerm_key_vault_key.data_encryption[0].versionless_id : null
  analytical_storage_enabled = var.cosmosDB.analytics.enable
  mongo_server_version       = var.cosmosMongoDB.version
  ip_range_filter            = local.azurePortalAddresses
  default_identity_type      = "UserAssignedIdentity=${data.azurerm_user_assigned_identity.studio.id}"
  kind                       = "MongoDB"
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
    name = "EnableMongo"
  }
  capabilities {
    name = "EnableMongoRoleBasedAccessControl"
  }
  analytical_storage {
    schema_type = var.cosmosDB.analytics.schemaType
  }
  dynamic capabilities {
    for_each = var.cosmosDB.aggregationPipeline.enable ? [1] : []
    content {
      name = "EnableAggregationPipeline"
    }
  }
  dynamic geo_location {
    for_each = local.regionNames
    content {
      location          = geo_location.value
      failover_priority = index(local.regionNames, geo_location.value)
    }
  }
}

resource azurerm_cosmosdb_mongo_database mongo_db {
  count               = var.cosmosMongoDB.enable ? 1 : 0
  name                = var.cosmosMongoDB.database.name
  resource_group_name = azurerm_resource_group.database[0].name
  account_name        = azurerm_cosmosdb_account.mongo_db[0].name
  throughput          = var.cosmosMongoDB.database.throughput
}

#####################################################################################################
# Cosmos DB Mongo DB vCore (https://learn.microsoft.com/azure/cosmos-db/mongodb/vcore/introduction) #
#####################################################################################################

resource azurerm_private_dns_zone mongo_cluster {
  count               = var.cosmosMongoDB.vCore.enable ? 1 : 0
  name                = "privatelink.mongocluster.cosmos.azure.com"
  resource_group_name = azurerm_resource_group.database[0].name
}

resource azurerm_private_dns_zone_virtual_network_link mongo_cluster {
  count                 = var.cosmosMongoDB.vCore.enable ? 1 : 0
  name                  = "mongo-cluster"
  resource_group_name   = azurerm_resource_group.database[0].name
  private_dns_zone_name = azurerm_private_dns_zone.mongo_cluster[0].name
  virtual_network_id    = data.azurerm_virtual_network.studio.id
}

resource azurerm_private_endpoint mongo_cluster {
  count               = var.cosmosMongoDB.vCore.enable ? 1 : 0
  name                = "${azapi_resource.mongo_cluster[0].name}-${azurerm_private_dns_zone_virtual_network_link.mongo_cluster[0].name}"
  resource_group_name = azurerm_resource_group.database[0].name
  location            = azurerm_resource_group.database[0].location
  subnet_id           = data.azurerm_subnet.farm.id
  private_service_connection {
    name                           = azapi_resource.mongo_cluster[0].name
    private_connection_resource_id = azapi_resource.mongo_cluster[0].id
    is_manual_connection           = false
    subresource_names = [
      "MongoCluster"
    ]
  }
  private_dns_zone_group {
    name = azapi_resource.mongo_cluster[0].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.mongo_cluster[0].id
    ]
  }
  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.mongo_cluster
  ]
}

resource azapi_resource mongo_cluster {
  count     = var.cosmosMongoDB.vCore.enable ? 1 : 0
  name      = var.cosmosMongoDB.vCore.name
  type      = "Microsoft.DocumentDB/mongoClusters@2023-11-15-preview"
  parent_id = azurerm_resource_group.database[0].id
  location  = azurerm_resource_group.database[0].location
  body = jsonencode({
    properties = {
      nodeGroupSpecs = [
        {
          kind       = "Shard"
          sku        = var.cosmosMongoDB.vCore.tier
          nodeCount  = var.cosmosMongoDB.vCore.nodeCount
          diskSizeGB = var.cosmosMongoDB.vCore.diskSizeGB
          enableHa   = var.cosmosMongoDB.vCore.highAvailability.enable
        }
      ]
      serverVersion              = var.cosmosMongoDB.vCore.version
      administratorLogin         = data.azurerm_key_vault_secret.admin_username.value
      administratorLoginPassword = data.azurerm_key_vault_secret.admin_password.value
    }
  })
}
