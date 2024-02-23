########################################################################
# Cosmos DB (https://learn.microsoft.com/azure/cosmos-db/introduction) #
########################################################################

variable cosmosDB {
  type = object({
    accountName = string
    offerType   = string
    dataConsistency = object({
      policyLevel        = string
      maxIntervalSeconds = number
      maxStalenessPrefix = number
    })
    serverless = object({
      enable = bool
    })
    aggregationPipeline = object({
      enable = bool
    })
    analyticalStorage = object({
      enable     = bool
      schemaType = string
    })
    secondaryEncryption = object({
      enable  = bool
      keyName = string
    })
    automaticFailover = object({
      enable = bool
    })
    partitionMerge = object({
      enable = bool
    })
    multiRegionWrite = object({
      enable = bool
    })
  })
}

data azuread_service_principal cosmos_db {
  display_name = "Azure Cosmos DB"
}

data azurerm_key_vault_key data_encryption {
  count        = var.cosmosDB.secondaryEncryption.enable ? 1 : 0
  name         = var.cosmosDB.secondaryEncryption.keyName != "" ? var.cosmosDB.secondaryEncryption.keyName : module.global.keyVault.keyName.dataEncryption
  key_vault_id = data.azurerm_key_vault.studio.id
}

locals {
  cosmosAccountTypes = toset(compact([
    var.cosmosNoSQL.enable ? "sql" : null,
    var.cosmosMongoDB.enable ? "mongo" : null,
    var.cosmosCassandra.enable ? "cassandra" : null,
    var.cosmosGremlin.enable ? "gremlin" : null,
    var.cosmosTable.enable ? "table" : null
  ]))
}

resource azurerm_role_assignment key_vault {
  count                = var.cosmosDB.secondaryEncryption.enable ? 1 : 0
  role_definition_name = "Key Vault Crypto User" # https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#key-vault-crypto-user
  principal_id         = data.azurerm_user_assigned_identity.studio.principal_id
  scope                = data.azurerm_key_vault.studio.id
}

resource azurerm_cosmosdb_account studio {
  for_each                        = local.cosmosAccountTypes
  name                            = var.cosmosDB.accountName
  resource_group_name             = azurerm_resource_group.database.name
  location                        = azurerm_resource_group.database.location
  kind                            = each.value == "mongo" ? "MongoDB" : "GlobalDocumentDB"
  mongo_server_version            = each.value == "mongo" ? var.cosmosMongoDB.version : null
  offer_type                      = var.cosmosDB.offerType
  key_vault_key_id                = var.cosmosDB.secondaryEncryption.enable ? data.azurerm_key_vault_key.data_encryption[0].versionless_id : null
  analytical_storage_enabled      = var.cosmosDB.analyticalStorage.enable
  partition_merge_enabled         = var.cosmosDB.partitionMerge.enable
  enable_multiple_write_locations = var.cosmosDB.multiRegionWrite.enable
  enable_automatic_failover       = var.cosmosDB.automaticFailover.enable
  ip_range_filter                 = "104.42.195.92,40.76.54.131,52.176.6.30,52.169.50.45,52.187.184.26" # Azure Portal
  default_identity_type           = "UserAssignedIdentity=${data.azurerm_user_assigned_identity.studio.id}"
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  consistency_policy {
    consistency_level       = var.cosmosDB.dataConsistency.policyLevel
    max_interval_in_seconds = var.cosmosDB.dataConsistency.maxIntervalSeconds
    max_staleness_prefix    = var.cosmosDB.dataConsistency.maxStalenessPrefix
  }
  dynamic geo_location {
    for_each = local.regionNames
    content {
      location          = geo_location.value
      failover_priority = index(local.regionNames, geo_location.value)
    }
  }
  dynamic analytical_storage {
    for_each = var.cosmosDB.analyticalStorage.schemaType != "" ? [1] : []
    content {
      schema_type = var.cosmosDB.analyticalStorage.schemaType
    }
  }
  dynamic capabilities {
    for_each = var.cosmosDB.serverless.enable ? ["EnableServerless"] : []
    content {
      name = capabilities.value
    }
  }
  dynamic capabilities {
    for_each = var.cosmosDB.aggregationPipeline.enable ? ["EnableAggregationPipeline"] : []
    content {
      name = capabilities.value
    }
  }
  dynamic capabilities {
    for_each = each.value == "mongo" ? ["EnableMongo", "EnableMongoRoleBasedAccessControl"] : []
    content {
      name = capabilities.value
    }
  }
  dynamic capabilities {
    for_each = each.value == "cassandra" ? ["EnableCassandra"] : []
    content {
      name = capabilities.value
    }
  }
  dynamic capabilities {
    for_each = each.value == "gremlin" ? ["EnableGremlin"] : []
    content {
      name = capabilities.value
    }
  }
  dynamic capabilities {
    for_each = each.value == "table" ? ["EnableTable"] : []
    content {
      name = capabilities.value
    }
  }
  depends_on = [
    azurerm_role_assignment.key_vault
  ]
}
