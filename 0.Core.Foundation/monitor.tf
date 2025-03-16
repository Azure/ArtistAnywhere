######################################################################
# Monitor (https://learn.microsoft.com/azure/azure-monitor/overview) #
######################################################################

variable monitor {
  type = object({
    grafanaDashboard = object({
      type    = string
      version = number
      apiKey = object({
        enable = bool
      })
    })
    appInsights = object({
      type = string
    })
    logAnalytics = object({
      workspace = object({
        type = string
      })
    })
    retentionDays = number
  })
}

resource azurerm_monitor_workspace studio {
  name                          = module.core.monitor.name
  resource_group_name           = azurerm_resource_group.studio_monitor.name
  location                      = azurerm_resource_group.studio_monitor.location
  public_network_access_enabled = false
}

resource azurerm_dashboard_grafana studio {
  name                          = module.core.monitor.name
  resource_group_name           = azurerm_resource_group.studio_monitor.name
  location                      = azurerm_resource_group.studio_monitor.location
  sku                           = var.monitor.grafanaDashboard.type
  grafana_major_version         = var.monitor.grafanaDashboard.version
  api_key_enabled               = var.monitor.grafanaDashboard.apiKey.enable
  public_network_access_enabled = false
  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.studio.id
    ]
  }
  azure_monitor_workspace_integrations {
    resource_id = azurerm_monitor_workspace.studio.id
  }
}

resource azurerm_log_analytics_workspace studio {
  name                       = module.core.monitor.name
  resource_group_name        = azurerm_resource_group.studio_monitor.name
  location                   = azurerm_resource_group.studio_monitor.location
  sku                        = var.monitor.logAnalytics.workspace.type
  retention_in_days          = var.monitor.retentionDays
  internet_ingestion_enabled = false
  internet_query_enabled     = false
  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.studio.id
    ]
  }
}

resource azurerm_application_insights studio {
  name                       = module.core.monitor.name
  resource_group_name        = azurerm_resource_group.studio_monitor.name
  location                   = azurerm_resource_group.studio_monitor.location
  workspace_id               = azurerm_log_analytics_workspace.studio.id
  application_type           = var.monitor.appInsights.type
  retention_in_days          = var.monitor.retentionDays
  internet_ingestion_enabled = false
  internet_query_enabled     = false
}

output monitor {
  value = {
    resourceGroup = {
      name     = azurerm_resource_group.studio_monitor.name
      location = azurerm_resource_group.studio_monitor.location
    }
    dataCollection = {
      endpoint = {
        id = azurerm_monitor_workspace.studio.default_data_collection_endpoint_id
      }
      rule = {
        id = azurerm_monitor_workspace.studio.default_data_collection_rule_id
      }
    }
    workspace = {
      url = azurerm_monitor_workspace.studio.query_endpoint
    }
    grafana = {
      url = azurerm_dashboard_grafana.studio.endpoint
    }
    logAnalytics = {
      id = azurerm_log_analytics_workspace.studio.id
    }
    appInsights = {
      id = azurerm_application_insights.studio.id
    }
  }
}
