########################################################################
# Cosmos DB (https://learn.microsoft.com/azure/cosmos-db/introduction) #
########################################################################

variable cosmosDB {
  type = object({
    offerType = string
    dataConsistency = object({
      policyLevel        = string
      maxIntervalSeconds = number
      maxStalenessPrefix = number
    })
    aggregationPipeline = object({
      enable = bool
    })
    analyticalStorage = object({
      enable     = bool
      schemaType = string
    })
    automaticFailover = object({
      enable = bool
    })
    multiRegionWrite = object({
      enable = bool
    })
    partitionMerge = object({
      enable = bool
    })
    serverless = object({
      enable = bool
    })
    secondaryEncryption = object({
      enable  = bool
      keyName = string
    })
    dedicatedGateway = object({
      enable = bool
      size   = string
      count  = number
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
  cosmosAccounts = [
    {
      id = "${azurerm_resource_group.database.id}/providers/Microsoft.DocumentDB/databaseAccounts/${var.cosmosNoSQL.account.name}"
      name = var.cosmosNoSQL.enable ? var.cosmosNoSQL.account.name : ""
      type = "sql"
    },
    {
      id = "${azurerm_resource_group.database.id}/providers/Microsoft.DocumentDB/databaseAccounts/${var.cosmosMongoDB.account.name}"
      name = var.cosmosMongoDB.enable ? var.cosmosMongoDB.account.name : ""
      type = "mongo"
    },
    {
      id = "${azurerm_resource_group.database.id}/providers/Microsoft.DocumentDB/databaseAccounts/${var.cosmosCassandra.account.name}"
      name = var.cosmosCassandra.enable ? var.cosmosCassandra.account.name : ""
      type = "cassandra"
    },
    {
      id = "${azurerm_resource_group.database.id}/providers/Microsoft.DocumentDB/databaseAccounts/${var.cosmosGremlin.account.name}"
      name = var.cosmosGremlin.enable ? var.cosmosGremlin.account.name : ""
      type = "gremlin"
    },
    {
      id = "${azurerm_resource_group.database.id}/providers/Microsoft.DocumentDB/databaseAccounts/${var.cosmosTable.account.name}"
      name = var.cosmosTable.enable ? var.cosmosTable.account.name : ""
      type = "table"
    }
  ]
}

resource azurerm_role_assignment key_vault {
  count                = var.cosmosDB.secondaryEncryption.enable ? 1 : 0
  role_definition_name = "Key Vault Crypto Service Encryption User" # https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#key-vault-crypto-service-encryption-user
  principal_id         = data.azurerm_user_assigned_identity.studio.principal_id
  scope                = data.azurerm_key_vault.studio.id
}

resource azurerm_cosmosdb_account studio {
  for_each = {
    for cosmosAccount in local.cosmosAccounts : cosmosAccount.type => cosmosAccount if cosmosAccount.name != ""
  }
  name                            = each.value.name
  resource_group_name             = azurerm_resource_group.database.name
  location                        = azurerm_resource_group.database.location
  kind                            = each.value.type == "mongo" ? "MongoDB" : "GlobalDocumentDB"
  mongo_server_version            = each.value.type == "mongo" ? var.cosmosMongoDB.account.version : null
  offer_type                      = var.cosmosDB.offerType
  key_vault_key_id                = var.cosmosDB.secondaryEncryption.enable ? data.azurerm_key_vault_key.data_encryption[0].versionless_id : null
  analytical_storage_enabled      = var.cosmosDB.analyticalStorage.enable
  partition_merge_enabled         = var.cosmosDB.partitionMerge.enable
  enable_multiple_write_locations = var.cosmosDB.multiRegionWrite.enable
  enable_automatic_failover       = var.cosmosDB.automaticFailover.enable
  ip_range_filter                 = "${jsondecode(data.http.client_address.response_body).ip},104.42.195.92,40.76.54.131,52.176.6.30,52.169.50.45,52.187.184.26" # Azure Portal
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
    for_each = each.value.type == "mongo" ? ["EnableMongo", "EnableMongoRoleBasedAccessControl"] : []
    content {
      name = capabilities.value
    }
  }
  dynamic capabilities {
    for_each = each.value.type == "cassandra" ? ["EnableCassandra"] : []
    content {
      name = capabilities.value
    }
  }
  dynamic capabilities {
    for_each = each.value.type == "gremlin" ? ["EnableGremlin"] : []
    content {
      name = capabilities.value
    }
  }
  dynamic capabilities {
    for_each = each.value.type == "table" ? ["EnableTable"] : []
    content {
      name = capabilities.value
    }
  }
  depends_on = [
    azurerm_role_assignment.key_vault
  ]
}

resource azurerm_cosmosdb_sql_dedicated_gateway no_sql {
  for_each = {
    for cosmosAccount in local.cosmosAccounts : cosmosAccount.type => cosmosAccount if cosmosAccount.name != "" && var.cosmosDB.dedicatedGateway.enable
  }
  cosmosdb_account_id = each.value.id
  instance_size       = var.cosmosDB.dedicatedGateway.size
  instance_count      = var.cosmosDB.dedicatedGateway.count
}
