######################################################################
# Monitor (https://learn.microsoft.com/azure/azure-monitor/overview) #
######################################################################

variable monitor {
  type = object({
    logWorkspace = object({
      tier = string
    })
    appInsight = object({
      type = string
    })
    retentionDays = number
  })
}

data azuread_service_principal monitor_diagnostics {
  display_name = "Diagnostic Services Trusted Storage Access"
}

resource azurerm_role_assignment storage_blob_data_contributor {
  role_definition_name = "Storage Blob Data Contributor" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/storage#storage-blob-data-contributor
  principal_id         = data.azuread_service_principal.monitor_diagnostics.object_id
  scope                = azurerm_storage_account.studio.id
}

resource time_sleep monitor_diagnostics_rbac {
  create_duration = "30s"
  depends_on = [
    azurerm_role_assignment.storage_blob_data_contributor
  ]
}

resource azurerm_log_analytics_workspace studio {
  name                       = module.global.monitor.name
  resource_group_name        = azurerm_resource_group.studio_monitor.name
  location                   = azurerm_resource_group.studio_monitor.location
  sku                        = var.monitor.logWorkspace.tier
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
  name                       = module.global.monitor.name
  resource_group_name        = azurerm_resource_group.studio_monitor.name
  location                   = azurerm_resource_group.studio_monitor.location
  workspace_id               = azurerm_log_analytics_workspace.studio.id
  application_type           = var.monitor.appInsight.type
  retention_in_days          = var.monitor.retentionDays
  internet_ingestion_enabled = false
  internet_query_enabled     = false
  depends_on = [
    time_sleep.monitor_diagnostics_rbac
  ]
}

resource terraform_data monitor_storage {
  provisioner local-exec {
    command = "az monitor app-insights component linked-storage link --id ${azurerm_application_insights.studio.id} --storage-account ${azurerm_storage_account.studio.id}"
  }
  depends_on = [
    azurerm_application_insights.studio,
    azurerm_storage_account.studio
  ]
}

resource azurerm_monitor_data_collection_endpoint studio {
  name                          = module.global.monitor.name
  resource_group_name           = azurerm_resource_group.studio_monitor.name
  location                      = azurerm_resource_group.studio_monitor.location
  public_network_access_enabled = false
  depends_on = [
    azurerm_user_assigned_identity.studio
  ]
}

resource time_sleep monitor_data_collection_endpoint {
  create_duration = "180s"
  depends_on = [
    azurerm_monitor_data_collection_endpoint.studio
  ]
}

resource azurerm_monitor_data_collection_rule studio {
  name                        = module.global.monitor.name
  resource_group_name         = azurerm_resource_group.studio_monitor.name
  location                    = azurerm_resource_group.studio_monitor.location
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.studio.id
  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.studio.id
    ]
  }
  data_flow {
    streams = [
      "Microsoft-Perf"
    ]
    destinations = [
      "LogAnalyticsWorkspace"
    ]
  }
  destinations {
    log_analytics {
      name                  = "LogAnalyticsWorkspace"
      workspace_resource_id = azurerm_log_analytics_workspace.studio.id
    }
  }
  depends_on = [
    time_sleep.monitor_data_collection_endpoint
  ]
}

resource azurerm_monitor_diagnostic_setting key_vault {
  name                       = azurerm_key_vault.studio.name
  target_resource_id         = azurerm_key_vault.studio.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.studio.id
  enabled_log {
    category = "AuditEvent"
  }
  metric {
    category = "AllMetrics"
  }
}

output monitor {
  value = {
    resourceGroupName = azurerm_resource_group.studio_monitor.name
  }
}
