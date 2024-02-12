######################################################################
# Monitor (https://learn.microsoft.com/azure/azure-monitor/overview) #
######################################################################

variable monitor {
  type = object({
    workspace = object({
      sku = string
    })
    insight = object({
      type = string
    })
    retentionDays = number
  })
}

resource azurerm_log_analytics_workspace monitor {
  name                       = module.global.monitor.name
  resource_group_name        = azurerm_resource_group.studio.name
  location                   = azurerm_resource_group.studio.location
  sku                        = var.monitor.workspace.sku
  retention_in_days          = var.monitor.retentionDays
  internet_ingestion_enabled = false
  internet_query_enabled     = false
}

resource azurerm_application_insights monitor {
  name                       = module.global.monitor.name
  resource_group_name        = azurerm_resource_group.studio.name
  location                   = azurerm_resource_group.studio.location
  workspace_id               = azurerm_log_analytics_workspace.monitor.id
  application_type           = var.monitor.insight.type
  retention_in_days          = var.monitor.retentionDays
  internet_ingestion_enabled = false
  internet_query_enabled     = false
}

# resource azapi_resource monitor_storage {
#   name      = azurerm_storage_account.studio.name
#   type      = "Microsoft.Insights/components/linkedStorageAccounts@2020-03-01-preview"
#   parent_id = azurerm_application_insights.monitor.id
#   body = jsonencode({
#     properties = {
#       linkedStorageAccount = azurerm_storage_account.studio.id
#     }
#   })
# }
