#########################################################################################
# Cosmos DB Mongo DB (https://learn.microsoft.com/azure/cosmos-db/mongodb/introduction) #
#########################################################################################

variable mongoDB {
  type = object({
    enable  = bool
    account = object({
      name    = string
      version = string
    })
    databases = list(object({
      enable     = bool
      name       = string
      throughput = number
      collections = list(object({
        enable     = bool
        name       = string
        shardKey   = string
        throughput = number
        indices = list(object({
          enable = bool
          unique = bool
          keys   = list(string)
        }))
      }))
      roles = list(object({
        enable    = bool
        name      = string
        roleNames = list(string)
        privileges = list(object({
          enable = bool
          resource = object({
            databaseName   = string
            collectionName = string
          })
          actions = list(string)
        }))
      }))
      users = list(object({
        enable    = bool
        username  = string
        password  = string
        roleNames = list(string)
      }))
    }))
  })
}

variable mongoDBvCore {
  type = object({
    enable = bool
    cluster = object({
      name    = string
      tier    = string
      version = string
      adminLogin = object({
        userName     = string
        userPassword = string
      })
    })
    node = object({
      count      = number
      diskSizeGB = number
    })
    highAvailability = object({
      enable = bool
    })
  })
}

locals {
  collections = flatten([
    for database in var.mongoDB.databases : [
      for collection in database.collections : merge(collection, {
        key          = "${database.name}-${collection.name}"
        databaseName = database.name
       }) if collection.enable
    ] if database.enable
  ])
  roles = flatten([
    for database in var.mongoDB.databases : [
      for role in database.roles : merge(role, {
        key        = "${database.name}-${role.name}"
        databaseId = "${azurerm_cosmosdb_account.studio["mongo"].id}/sqlDatabases/${database.name}"
       }) if role.enable
    ] if database.enable
  ])
  users = flatten([
    for database in var.mongoDB.databases : [
      for user in database.users : merge(user, {
        key        = "${database.name}-${user.name}"
        databaseId = "${azurerm_cosmosdb_account.studio["mongo"].id}/sqlDatabases/${database.name}"
       }) if user.enable
    ] if database.enable
  ])
}

###############################################################################################
# Cosmos DB Mongo DB RU (https://learn.microsoft.com/azure/cosmos-db/mongodb/ru/introduction) #
###############################################################################################

resource azurerm_cosmosdb_mongo_database mongo_db {
  for_each = {
    for database in var.mongoDB.databases : database.name => database if var.mongoDB.enable && database.enable
  }
  name                = each.value.name
  resource_group_name = azurerm_cosmosdb_account.studio["mongo"].resource_group_name
  account_name        = azurerm_cosmosdb_account.studio["mongo"].name
  throughput          = each.value.throughput
}

resource azurerm_cosmosdb_mongo_collection mongo_db {
  for_each = {
    for collection in local.collections : collection.name => collection if var.mongoDB.enable
  }
  name                = each.value.name
  resource_group_name = azurerm_cosmosdb_account.studio["mongo"].resource_group_name
  account_name        = azurerm_cosmosdb_account.studio["mongo"].name
  database_name       = each.value.databaseName
  throughput          = each.value.throughput
  shard_key           = each.value.shardKey
  dynamic index {
    for_each = {
      for index in each.value.indices : join("-", index.keys) => index if index.enable
    }
    content {
      unique = index.value["unique"]
      keys   = index.value["keys"]
    }
  }
}

resource azurerm_cosmosdb_mongo_role_definition mongo_db {
  for_each = {
    for role in local.roles : role.name => role if var.mongoDB.enable
  }
  role_name                = each.value.name
  cosmos_mongo_database_id = each.value.databaseId
  inherited_role_names     = each.value.roleNames
  dynamic privilege {
    for_each = {
      for privilege in each.value.privileges : "${privilege.resource.databaseName}-${privilege.resource.collectionName}" => privilege if privilege.enable
    }
    content {
      resource {
        db_name         = privilege.value["resource"].databaseName
        collection_name = privilege.value["resource"].collectionName
      }
      actions = privilege.value["actions"]
    }
  }
}

resource azurerm_cosmosdb_mongo_user_definition mongo_db {
  for_each = {
    for user in local.users : user.username => user if var.mongoDB.enable
  }
  cosmos_mongo_database_id = each.value.databaseId
  username                 = each.value.username
  password                 = each.value.password
  inherited_role_names     = each.value.roleNames
  depends_on = [
    azurerm_cosmosdb_mongo_role_definition.mongo_db
  ]
}

resource azurerm_private_dns_zone mongo_db {
  count               = var.mongoDB.enable ? 1 : 0
  name                = "privatelink.mongo.cosmos.azure.com"
  resource_group_name = azurerm_cosmosdb_account.studio["mongo"].resource_group_name
}

resource azurerm_private_dns_zone_virtual_network_link mongo_db {
  count                 = var.mongoDB.enable ? 1 : 0
  name                  = "mongo"
  resource_group_name   = azurerm_private_dns_zone.mongo_db[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.mongo_db[0].name
  virtual_network_id    = data.azurerm_virtual_network.studio_region.id
}

resource azurerm_private_endpoint mongo_db {
  count               = var.mongoDB.enable ? 1 : 0
  name                = azurerm_cosmosdb_account.studio["mongo"].name
  resource_group_name = azurerm_cosmosdb_account.studio["mongo"].resource_group_name
  location            = azurerm_cosmosdb_account.studio["mongo"].location
  subnet_id           = data.azurerm_subnet.data.id
  private_service_connection {
    name                           = azurerm_cosmosdb_account.studio["mongo"].name
    private_connection_resource_id = azurerm_cosmosdb_account.studio["mongo"].id
    is_manual_connection           = false
    subresource_names = [
      "MongoDB"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.mongo_db[0].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.mongo_db[0].id
    ]
  }
}

#####################################################################################################
# Cosmos DB Mongo DB vCore (https://learn.microsoft.com/azure/cosmos-db/mongodb/vcore/introduction) #
#####################################################################################################

resource azapi_resource mongo_cluster {
  count     = var.mongoDBvCore.enable ? 1 : 0
  name      = var.mongoDBvCore.cluster.name
  type      = "Microsoft.DocumentDB/mongoClusters@2024-06-01-preview"
  parent_id = azurerm_resource_group.data.id
  location  = azurerm_resource_group.data.location
  body = jsonencode({
    properties = {
      nodeGroupSpecs = [
        {
          kind       = "Shard"
          sku        = var.mongoDBvCore.cluster.tier
          nodeCount  = var.mongoDBvCore.node.count
          diskSizeGB = var.mongoDBvCore.node.diskSizeGB
          enableHa   = var.mongoDBvCore.highAvailability.enable
        }
      ]
      serverVersion              = var.mongoDBvCore.cluster.version
      administratorLogin         = var.mongoDBvCore.cluster.adminLogin.userName != "" ? var.mongoDBvCore.cluster.adminLogin.userName : data.azurerm_key_vault_secret.admin_username.value
      administratorLoginPassword = var.mongoDBvCore.cluster.adminLogin.userPassword != "" ? var.mongoDBvCore.cluster.adminLogin.userPassword : data.azurerm_key_vault_secret.admin_password.value
    }
  })
  schema_validation_enabled = false
}

resource azapi_resource mongo_cluster_firewall_rule_allow_azure {
  count     = var.mongoDBvCore.enable ? 1 : 0
  name      = "AllowAllAzureServicesAndResourcesWithinAzureIps"
  type      = "Microsoft.DocumentDB/mongoClusters/firewallRules@2024-06-01-preview"
  parent_id = azapi_resource.mongo_cluster[0].id
  body = jsonencode({
    properties = {
      startIpAddress = "0.0.0.0"
      endIpAddress   = "0.0.0.0"
    }
  })
  schema_validation_enabled = false
}

resource azapi_resource mongo_cluster_firewall_rule_allow_client {
  count     = var.mongoDBvCore.enable ? 1 : 0
  name      = "AllowClient"
  type      = "Microsoft.DocumentDB/mongoClusters/firewallRules@2024-06-01-preview"
  parent_id = azapi_resource.mongo_cluster[0].id
  body = jsonencode({
    properties = {
      startIpAddress = jsondecode(data.http.client_address.response_body).ip
      endIpAddress = jsondecode(data.http.client_address.response_body).ip
    }
  })
  schema_validation_enabled = false
}

resource azurerm_private_dns_zone mongo_cluster {
  count               = var.mongoDBvCore.enable ? 1 : 0
  name                = "privatelink.mongocluster.cosmos.azure.com"
  resource_group_name = azurerm_resource_group.data.name
}

resource azurerm_private_dns_zone_virtual_network_link mongo_cluster {
  count                 = var.mongoDBvCore.enable ? 1 : 0
  name                  = "mongo-cluster"
  resource_group_name   = azurerm_private_dns_zone.mongo_cluster[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.mongo_cluster[0].name
  virtual_network_id    = data.azurerm_virtual_network.studio_region.id
}

resource azurerm_private_endpoint mongo_cluster {
  count               = var.mongoDBvCore.enable ? 1 : 0
  name                = "${azapi_resource.mongo_cluster[0].name}-${azurerm_private_dns_zone_virtual_network_link.mongo_cluster[0].name}"
  resource_group_name = azurerm_resource_group.data.name
  location            = azurerm_resource_group.data.location
  subnet_id           = data.azurerm_subnet.data.id
  private_service_connection {
    name                           = azapi_resource.mongo_cluster[0].name
    private_connection_resource_id = azapi_resource.mongo_cluster[0].id
    is_manual_connection           = false
    subresource_names = [
      "MongoCluster"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.mongo_cluster[0].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.mongo_cluster[0].id
    ]
  }
}
