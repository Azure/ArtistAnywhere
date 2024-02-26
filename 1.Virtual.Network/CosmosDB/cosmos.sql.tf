########################################################################
# Cosmos DB NoSQL (https://learn.microsoft.com/azure/cosmos-db/nosql/) #
########################################################################

variable cosmosNoSQL {
  type = object({
    enable = bool
    account = object({
      name = string
    })
    database = object({
      enable     = bool
      name       = string
      throughput = number
      containers = list(object({
        enable     = bool
        name       = string
        throughput = number
        partitionKey = object({
          path    = string
          version = number
        })
        storedProcedures = list(object(
          {
            enable = bool
            name   = string
            body   = string
          }
        ))
        triggers = list(object(
          {
            enable    = bool
            name      = string
            type      = string
            operation = string
            body      = string
          }
        ))
        functions = list(object(
          {
            enable = bool
            name   = string
            body   = string
          }
        ))
      }))
    })
    gateway = object({
      enable = bool
      size   = string
      count  = number
    })
  })
}

locals {
  storedProcedures = flatten([
    for container in var.cosmosNoSQL.database.containers : [
      for storedProcedure in container.storedProcedures : merge(storedProcedure, {
        key           = "${container.name}-${storedProcedure.name}"
        containerName = container.name
      }) if storedProcedure.enable
    ] if container.enable
  ])
  triggers = flatten([
    for container in var.cosmosNoSQL.database.containers : [
      for trigger in container.triggers : merge(trigger, {
        key         = "${container.name}-${trigger.name}"
        containerId = "${azurerm_resource_group.database.id}/providers/Microsoft.DocumentDB/databaseAccounts/${var.cosmosNoSQL.account.name}/sqlDatabases/${var.cosmosNoSQL.database.name}/containers/${container.name}"
      }) if trigger.enable
    ] if container.enable
  ])
  functions = flatten([
    for container in var.cosmosNoSQL.database.containers : [
      for function in container.functions : merge(function, {
        key         = "${container.name}-${function.name}"
        containerId = "${azurerm_resource_group.database.id}/providers/Microsoft.DocumentDB/databaseAccounts/${var.cosmosNoSQL.account.name}/sqlDatabases/${var.cosmosNoSQL.database.name}/containers/${container.name}"
      }) if function.enable
    ] if container.enable
  ])
}

resource azurerm_private_dns_zone no_sql {
  count               = var.cosmosNoSQL.enable || var.cosmosGremlin.enable || var.cosmosTable.enable ? 1 : 0
  name                = var.cosmosNoSQL.gateway.enable ? "privatelink.sqlx.cosmos.azure.com" : "privatelink.documents.azure.com"
  resource_group_name = azurerm_resource_group.database.name
}

resource azurerm_private_dns_zone_virtual_network_link no_sql {
  count                 = var.cosmosNoSQL.enable || var.cosmosGremlin.enable || var.cosmosTable.enable ? 1 : 0
  name                  = "no-sql"
  resource_group_name   = azurerm_resource_group.database.name
  private_dns_zone_name = azurerm_private_dns_zone.no_sql[0].name
  virtual_network_id    = data.azurerm_virtual_network.studio.id
}

resource azurerm_private_endpoint no_sql {
  count               = var.cosmosNoSQL.enable ? 1 : 0
  name                = azurerm_cosmosdb_account.studio["sql"].name
  resource_group_name = azurerm_resource_group.database.name
  location            = azurerm_resource_group.database.location
  subnet_id           = data.azurerm_subnet.farm.id
  private_service_connection {
    name                           = azurerm_cosmosdb_account.studio["sql"].name
    private_connection_resource_id = azurerm_cosmosdb_account.studio["sql"].id
    is_manual_connection           = false
    subresource_names = [
      var.cosmosNoSQL.gateway.enable ? "SqlDedicated" : "Sql"
    ]
  }
  private_dns_zone_group {
    name = azurerm_cosmosdb_account.studio["sql"].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.no_sql[0].id
    ]
  }
  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.no_sql
  ]
}

resource azurerm_cosmosdb_sql_dedicated_gateway no_sql {
  count               = var.cosmosNoSQL.enable && var.cosmosNoSQL.gateway.enable ? 1 : 0
  cosmosdb_account_id = azurerm_cosmosdb_account.studio["sql"].id
  instance_size       = var.cosmosNoSQL.gateway.size
  instance_count      = var.cosmosNoSQL.gateway.count
}

resource azurerm_cosmosdb_sql_database no_sql {
  count               = var.cosmosNoSQL.enable && var.cosmosNoSQL.database.enable ? 1 : 0
  name                = var.cosmosNoSQL.database.name
  resource_group_name = azurerm_cosmosdb_account.studio["sql"].resource_group_name
  account_name        = azurerm_cosmosdb_account.studio["sql"].name
  throughput          = var.cosmosNoSQL.database.throughput
}

resource azurerm_cosmosdb_sql_container no_sql {
  for_each = {
    for sqlContainer in var.cosmosNoSQL.database.containers : sqlContainer.name => sqlContainer if var.cosmosNoSQL.enable && var.cosmosNoSQL.database.enable && sqlContainer.enable
  }
  name                  = each.value.name
  resource_group_name   = azurerm_cosmosdb_sql_database.no_sql[0].resource_group_name
  account_name          = azurerm_cosmosdb_sql_database.no_sql[0].account_name
  database_name         = azurerm_cosmosdb_sql_database.no_sql[0].name
  throughput            = each.value.throughput
  partition_key_path    = each.value.partitionKey.path
  partition_key_version = each.value.partitionKey.version
}

resource azurerm_cosmosdb_sql_stored_procedure no_sql {
  for_each = {
    for storedProcedure in local.storedProcedures : storedProcedure.key => storedProcedure
  }
  name                = each.value.name
  resource_group_name = azurerm_resource_group.database.name
  account_name        = var.cosmosNoSQL.account.name
  database_name       = var.cosmosNoSQL.database.name
  container_name      = each.value.containerName
  body                = each.value.body
  depends_on = [
    azurerm_cosmosdb_sql_container.no_sql
  ]
}

resource azurerm_cosmosdb_sql_trigger no_sql {
  for_each = {
    for trigger in local.triggers : trigger.key => trigger
  }
  name         = each.value.name
  container_id = each.value.containerId
  type         = each.value.type
  operation    = each.value.operation
  body         = each.value.body
  depends_on = [
    azurerm_cosmosdb_sql_container.no_sql
  ]
}

resource azurerm_cosmosdb_sql_function no_sql {
  for_each = {
    for function in local.functions : function.key => function
  }
  name         = each.value.name
  container_id = each.value.containerId
  body         = each.value.body
  depends_on = [
    azurerm_cosmosdb_sql_container.no_sql
  ]
}
