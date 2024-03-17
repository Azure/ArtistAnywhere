########################################################################
# Cosmos DB NoSQL (https://learn.microsoft.com/azure/cosmos-db/nosql/) #
########################################################################

variable noSQL {
  type = object({
    enable = bool
    account = object({
      name = string
      accessKeys = object({
        enable = bool
      })
      dedicatedGateway = object({
        enable = bool
        size   = string
        count  = number
      })
    })
    databases = list(object({
      enable = bool
      name   = string
      throughput = object({
        requestUnits = number
        autoScale = object({
          enable = bool
        })
      })
      containers = list(object({
        enable = bool
        name   = string
        throughput = object({
          requestUnits = number
          autoScale = object({
            enable = bool
          })
        })
        partitionKey = object({
          version = number
          paths   = list(string)
        })
        # geospatial = object({
        #   type = string
        # })
        indexPolicy = object({
          mode          = string
          includedPaths = list(string)
          excludedPaths = list(string)
          composite = list(object({
            enable = bool
            paths = list(object({
              enable = bool
              path   = string
              order  = string
            }))
          }))
          spatial = list(object({
            enable = bool
            path   = string
          }))
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
        timeToLive = object({
          default   = number
          analytics = number
        })
      }))
    }))
    roles = list(object({
      enable      = bool
      name        = string
      scopePaths  = list(string)
      permissions = list(string)
    }))
    roleAssignments = list(object({
      enable      = bool
      name        = string
      scopePath   = string
      principalId = string
      role = object({
        id   = string
        name = string
      })
    }))
  })
}

locals {
  containers = flatten([
    for database in var.noSQL.databases : [
      for container in database.containers : merge(container, {
        key          = "${database.name}-${container.name}"
        databaseName = database.name
       }) if container.enable
    ] if database.enable
  ])
  storedProcedures = flatten([
    for database in var.noSQL.databases : [
      for container in database.containers : [
        for storedProcedure in container.storedProcedures : merge(storedProcedure, {
          key           = "${container.name}-${storedProcedure.name}"
          containerName = container.name
        }) if storedProcedure.enable
      ] if container.enable
    ] if database.enable
  ])
  triggers = flatten([
    for database in var.noSQL.databases : [
      for container in database.containers : [
        for trigger in container.triggers : merge(trigger, {
          key         = "${database.name}-${container.name}-${trigger.name}"
          containerId = "${azurerm_cosmosdb_account.studio["sql"].id}/sqlDatabases/${database.name}/containers/${container.name}"
        }) if trigger.enable
      ] if container.enable
    ] if database.enable
  ])
  functions = flatten([
    for database in var.noSQL.databases : [
      for container in database.containers : [
        for function in container.functions : merge(function, {
          key         = "${database.name}-${container.name}-${function.name}"
          containerId = "${azurerm_cosmosdb_account.studio["sql"].id}/sqlDatabases/${database.name}/containers/${container.name}"
        }) if function.enable
      ] if container.enable
    ] if database.enable
  ])
}

resource azurerm_private_dns_zone no_sql {
  count               = var.noSQL.enable || var.gremlin.enable || var.table.enable ? 1 : 0
  name                = var.noSQL.account.dedicatedGateway.enable ? "privatelink.sqlx.cosmos.azure.com" : "privatelink.documents.azure.com"
  resource_group_name = azurerm_resource_group.database.name
}

resource azurerm_private_dns_zone_virtual_network_link no_sql {
  count                 = var.noSQL.enable || var.gremlin.enable || var.table.enable ? 1 : 0
  name                  = "no-sql"
  resource_group_name   = azurerm_private_dns_zone.no_sql[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.no_sql[0].name
  virtual_network_id    = data.azurerm_virtual_network.studio.id
}

resource azurerm_private_endpoint no_sql {
  count               = var.noSQL.enable ? 1 : 0
  name                = azurerm_cosmosdb_account.studio["sql"].name
  resource_group_name = azurerm_cosmosdb_account.studio["sql"].resource_group_name
  location            = azurerm_cosmosdb_account.studio["sql"].location
  subnet_id           = data.azurerm_subnet.data.id
  private_service_connection {
    name                           = azurerm_cosmosdb_account.studio["sql"].name
    private_connection_resource_id = azurerm_cosmosdb_account.studio["sql"].id
    is_manual_connection           = false
    subresource_names = [
      var.noSQL.account.dedicatedGateway.enable ? "SqlDedicated" : "Sql"
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
  count               = var.noSQL.enable && var.noSQL.account.dedicatedGateway.enable ? 1 : 0
  cosmosdb_account_id = azurerm_cosmosdb_account.studio["sql"].id
  instance_size       = var.noSQL.account.dedicatedGateway.size
  instance_count      = var.noSQL.account.dedicatedGateway.count
}

resource azurerm_cosmosdb_sql_database no_sql {
  for_each = {
    for database in var.noSQL.databases : database.name => database if var.noSQL.enable && database.enable
  }
  name                = each.value.name
  resource_group_name = azurerm_cosmosdb_account.studio["sql"].resource_group_name
  account_name        = azurerm_cosmosdb_account.studio["sql"].name
  throughput          = each.value.throughput.autoScale.enable ? null : each.value.throughput.requestUnits
  dynamic autoscale_settings {
    for_each = each.value.throughput.autoScale.enable ? [1] : []
    content {
      max_throughput = each.value.throughput.requestUnits
    }
  }
}

resource azurerm_cosmosdb_sql_container no_sql {
  for_each = {
    for container in local.containers : container.key => container if var.noSQL.enable
  }
  name                   = each.value.name
  resource_group_name    = azurerm_cosmosdb_account.studio["sql"].resource_group_name
  account_name           = azurerm_cosmosdb_account.studio["sql"].name
  database_name          = each.value.databaseName
  throughput             = each.value.throughput.autoScale.enable ? null : each.value.throughput.requestUnits
  partition_key_path     = each.value.partitionKey.paths[0]
  partition_key_version  = each.value.partitionKey.version
  analytical_storage_ttl = each.value.timeToLive.analytics
  default_ttl            = each.value.timeToLive.default
  indexing_policy {
    indexing_mode = each.value.indexPolicy.mode
    dynamic included_path {
      for_each = each.value.indexPolicy.includedPaths
      content {
        path = included_path.value
      }
    }
    dynamic excluded_path {
      for_each = each.value.indexPolicy.excludedPaths
      content {
        path = excluded_path.value
      }
    }
    dynamic composite_index {
      for_each = {
        for compositeIndex in each.value.indexPolicy.composite : join("-", compositeIndex.paths) => compositeIndex if compositeIndex.enable
      }
      content {
        dynamic index {
          for_each = {
            for index in composite_index.value["paths"] : index.path => index if index.enable
          }
          content {
            path  = index.value["path"]
            order = index.value["order"]
          }
        }
      }
    }
    dynamic spatial_index {
      for_each = {
        for spatialIndex in each.value.indexPolicy.spatial : spatialIndex.path => spatialIndex if spatialIndex.enable
      }
      content {
        path = spatial_index.value["path"]
      }
    }
  }
  dynamic autoscale_settings {
    for_each = each.value.throughput.autoScale.enable ? [1] : []
    content {
      max_throughput = each.value.throughput.requestUnits
    }
  }
  depends_on = [
    azurerm_cosmosdb_sql_database.no_sql
  ]
}

resource azurerm_cosmosdb_sql_stored_procedure no_sql {
  for_each = {
    for storedProcedure in local.storedProcedures : storedProcedure.key => storedProcedure if var.noSQL.enable
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
    for trigger in local.triggers : trigger.key => trigger if var.noSQL.enable
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
    for function in local.functions : function.key => function if var.noSQL.enable
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
    for role in var.noSQL.roles : role.name => role if var.noSQL.enable && role.enable
  }
  name                = each.value.name
  resource_group_name = azurerm_cosmosdb_account.studio["sql"].resource_group_name
  account_name        = azurerm_cosmosdb_account.studio["sql"].name
  assignable_scopes = [
    for scopePath in each.value.scopePaths :
      "${azurerm_cosmosdb_account.studio["sql"].id}${scopePath}"
  ]
  permissions {
    data_actions = each.value.permissions
  }
}
resource azurerm_cosmosdb_sql_role_assignment no_sql {
  for_each = {
    for roleAssignment in var.noSQL.roleAssignments : "${roleAssignment.role.id}-${roleAssignment.role.name}" => roleAssignment if var.noSQL.enable && roleAssignment.enable
  }
  resource_group_name = azurerm_cosmosdb_account.studio["sql"].resource_group_name
  account_name        = azurerm_cosmosdb_account.studio["sql"].name
  scope               = "${azurerm_cosmosdb_account.studio["sql"].id}${each.value.scopePath}"
  principal_id        = each.value.principalId
  role_definition_id  = each.value.role.id != "" ? "${azurerm_cosmosdb_account.studio["sql"].id}/sqlRoleDefinitions/${each.value.role.id}" : azurerm_cosmosdb_sql_role_definition.no_sql[each.value.role.Name].id
}
