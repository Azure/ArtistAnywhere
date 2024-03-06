########################################################################
# Cosmos DB NoSQL (https://learn.microsoft.com/azure/cosmos-db/nosql/) #
########################################################################

variable cosmosNoSQL {
  type = object({
    enable = bool
    account = object({
      name = string
      dedicatedGateway = object({
        enable = bool
        size   = string
        count  = number
      })
    })
    databases = list(object({
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
        dataAnalytics = object({
          ttl = number
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
    }))
    roles = list(object({
      enable      = bool
      name        = string
      scopePaths  = list(string)
      permissions = list(string)
    }))
    roleAssignments = list(object({
      enable            = bool
      name              = string
      roleName          = string
      scopePath         = string
      userPrincipalName = string
    }))
  })
}

data azuread_user role_assignment {
  for_each = {
    for roleAssignment in var.cosmosNoSQL.roleAssignments : roleAssignment.name => roleAssignment if var.cosmosNoSQL.enable && roleAssignment.enable
  }
  user_principal_name = each.value.userPrincipalName
}

locals {
  containers = flatten([
    for database in var.cosmosNoSQL.databases : [
      for container in database.containers : merge(container, {
        key          = "${database.name}-${container.name}"
        databaseName = database.name
       }) if container.enable
    ] if database.enable
  ])
  storedProcedures = flatten([
    for database in var.cosmosNoSQL.databases : [
      for container in var.cosmosNoSQL.database.containers : [
        for storedProcedure in container.storedProcedures : merge(storedProcedure, {
          key           = "${container.name}-${storedProcedure.name}"
          containerName = container.name
        }) if storedProcedure.enable
      ] if container.enable
    ] if database.enable
  ])
  triggers = flatten([
    for database in var.cosmosNoSQL.databases : [
      for container in database.containers : [
        for trigger in container.triggers : merge(trigger, {
          key         = "${database.name}-${container.name}-${trigger.name}"
          containerId = "${azurerm_resource_group.database.id}/providers/Microsoft.DocumentDB/databaseAccounts/${var.cosmosNoSQL.account.name}/sqlDatabases/${database.name}/containers/${container.name}"
        }) if trigger.enable
      ] if container.enable
    ] if database.enable
  ])
  functions = flatten([
    for database in var.cosmosNoSQL.databases : [
      for container in database.containers : [
        for function in container.functions : merge(function, {
          key         = "${database.name}-${container.name}-${function.name}"
          containerId = "${azurerm_resource_group.database.id}/providers/Microsoft.DocumentDB/databaseAccounts/${var.cosmosNoSQL.account.name}/sqlDatabases/${database.name}/containers/${container.name}"
        }) if function.enable
      ] if container.enable
    ] if database.enable
  ])
}

resource azurerm_private_dns_zone no_sql {
  count               = var.cosmosNoSQL.enable || var.cosmosGremlin.enable || var.cosmosTable.enable ? 1 : 0
  name                = var.cosmosNoSQL.account.dedicatedGateway.enable ? "privatelink.sqlx.cosmos.azure.com" : "privatelink.documents.azure.com"
  resource_group_name = azurerm_resource_group.database.name
}

resource azurerm_private_dns_zone_virtual_network_link no_sql {
  count                 = var.cosmosNoSQL.enable || var.cosmosGremlin.enable || var.cosmosTable.enable ? 1 : 0
  name                  = "no-sql"
  resource_group_name   = azurerm_private_dns_zone.no_sql[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.no_sql[0].name
  virtual_network_id    = data.azurerm_virtual_network.studio.id
}

resource azurerm_private_endpoint no_sql {
  count               = var.cosmosNoSQL.enable ? 1 : 0
  name                = azurerm_cosmosdb_account.studio["sql"].name
  resource_group_name = azurerm_resource_group.database.name
  location            = azurerm_resource_group.database.location
  subnet_id           = data.azurerm_subnet.data.id
  private_service_connection {
    name                           = azurerm_cosmosdb_account.studio["sql"].name
    private_connection_resource_id = azurerm_cosmosdb_account.studio["sql"].id
    is_manual_connection           = false
    subresource_names = [
      var.cosmosNoSQL.account.dedicatedGateway.enable ? "SqlDedicated" : "Sql"
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
  count               = var.cosmosNoSQL.enable && var.cosmosNoSQL.account.dedicatedGateway.enable ? 1 : 0
  cosmosdb_account_id = azurerm_cosmosdb_account.studio["sql"].id
  instance_size       = var.cosmosNoSQL.account.dedicatedGateway.size
  instance_count      = var.cosmosNoSQL.account.dedicatedGateway.count
}

resource azurerm_cosmosdb_sql_database no_sql {
  for_each = {
    for database in var.cosmosNoSQL.databases : database.name => database if var.cosmosNoSQL.enable && database.enable
  }
  name                = each.value.name
  resource_group_name = azurerm_cosmosdb_account.studio["sql"].resource_group_name
  account_name        = azurerm_cosmosdb_account.studio["sql"].name
  throughput          = each.value.throughput
}

resource azurerm_cosmosdb_sql_container no_sql {
  for_each = {
    for container in local.containers : container.name => container if var.cosmosNoSQL.enable
  }
  name                   = each.value.name
  resource_group_name    = azurerm_cosmosdb_sql_database.no_sql[0].resource_group_name
  account_name           = azurerm_cosmosdb_sql_database.no_sql[0].account_name
  database_name          = each.value.databaseName
  throughput             = each.value.throughput
  partition_key_path     = each.value.partitionKey.path
  partition_key_version  = each.value.partitionKey.version
  analytical_storage_ttl = each.value.dataAnalytics.ttl
}

resource azurerm_cosmosdb_sql_stored_procedure no_sql {
  for_each = {
    for storedProcedure in local.storedProcedures : storedProcedure.key => storedProcedure if var.cosmosNoSQL.enable
  }
  name                = each.value.name
  resource_group_name = azurerm_cosmosdb_account.studio["sql"].resource_group_name
  account_name        = azurerm_cosmosdb_account.studio["sql"].name
  database_name       = each.value.databaseName
  container_name      = each.value.containerName
  body                = each.value.body
  depends_on = [
    azurerm_cosmosdb_sql_container.no_sql
  ]
}

resource azurerm_cosmosdb_sql_trigger no_sql {
  for_each = {
    for trigger in local.triggers : trigger.key => trigger if var.cosmosNoSQL.enable
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
    for function in local.functions : function.key => function if var.cosmosNoSQL.enable
  }
  name         = each.value.name
  container_id = each.value.containerId
  body         = each.value.body
  depends_on = [
    azurerm_cosmosdb_sql_container.no_sql
  ]
}

resource azurerm_cosmosdb_sql_role_definition no_sql {
  for_each = {
    for role in var.cosmosNoSQL.roles : role.name => role if var.cosmosNoSQL.enable && role.enable
  }
  name                = each.value.name
  resource_group_name = azurerm_cosmosdb_account.studio["sql"].resource_group_name
  account_name        = azurerm_cosmosdb_account.studio["sql"].name
  assignable_scopes = [
    for scopePath in each.value.scopePaths :
      "${azurerm_resource_group.database.id}/providers/Microsoft.DocumentDB/databaseAccounts/${var.cosmosNoSQL.account.name}${scopePath}"
  ]
  permissions {
    data_actions = each.value.permissions
  }
}

resource azurerm_cosmosdb_sql_role_assignment no_sql {
  for_each = {
    for roleAssignment in var.cosmosNoSQL.roleAssignments : roleAssignment.name => roleAssignment if var.cosmosNoSQL.enable && roleAssignment.enable
  }
  resource_group_name = azurerm_cosmosdb_account.studio["sql"].resource_group_name
  account_name        = azurerm_cosmosdb_account.studio["sql"].name
  role_definition_id  = each.value.roleName
  scope               = "${azurerm_resource_group.database.id}/providers/Microsoft.DocumentDB/databaseAccounts/${var.cosmosNoSQL.account.name}${each.value.scopePath}"
  principal_id        = data.azuread_user.role_assignment[each.value.userPrincipalName].object_id
}
