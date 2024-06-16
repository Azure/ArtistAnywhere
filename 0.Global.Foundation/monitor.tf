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
  count        = module.global.monitor.enable ? 1 : 0
  display_name = "Diagnostic Services Trusted Storage Access"
}

resource azurerm_role_assignment storage_blob_data_contributor {
  count                = module.global.monitor.enable ? 1 : 0
  role_definition_name = "Storage Blob Data Contributor" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/storage#storage-blob-data-contributor
  principal_id         = data.azuread_service_principal.monitor_diagnostics[0].object_id
  scope                = azurerm_storage_account.studio[0].id
}

resource time_sleep monitor_diagnostics_rbac {
  count           = module.global.monitor.enable ? 1 : 0
  create_duration = "30s"
  depends_on = [
    azurerm_role_assignment.storage_blob_data_contributor
  ]
}

resource azurerm_log_analytics_workspace studio {
  count                      = module.global.monitor.enable ? 1 : 0
  name                       = module.global.monitor.name
  resource_group_name        = azurerm_resource_group.studio.name
  location                   = azurerm_resource_group.studio.location
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
  count                      = module.global.monitor.enable ? 1 : 0
  name                       = module.global.monitor.name
  resource_group_name        = azurerm_resource_group.studio.name
  location                   = azurerm_resource_group.studio.location
  workspace_id               = azurerm_log_analytics_workspace.studio[0].id
  application_type           = var.monitor.appInsight.type
  retention_in_days          = var.monitor.retentionDays
  internet_ingestion_enabled = false
  internet_query_enabled     = false
  depends_on = [
    time_sleep.monitor_diagnostics_rbac
  ]
}

resource terraform_data monitor_storage {
  count = module.global.monitor.enable ? 1 : 0
  provisioner local-exec {
    command = "az monitor app-insights component linked-storage link --id ${azurerm_application_insights.studio[0].id} --storage-account ${azurerm_storage_account.studio[0].id}"
  }
  depends_on = [
    azurerm_application_insights.studio,
    azurerm_storage_account.studio
  ]
}

resource azurerm_monitor_data_collection_endpoint studio {
  count                         = module.global.monitor.enable ? 1 : 0
  name                          = module.global.monitor.name
  resource_group_name           = azurerm_resource_group.studio.name
  location                      = azurerm_resource_group.studio.location
  public_network_access_enabled = false
  lifecycle {
    create_before_destroy = true
  }
  depends_on = [
    azurerm_user_assigned_identity.studio
  ]
}

resource azurerm_monitor_data_collection_rule studio {
  count                       = module.global.monitor.enable ? 1 : 0
  name                        = module.global.monitor.name
  resource_group_name         = azurerm_resource_group.studio.name
  location                    = azurerm_resource_group.studio.location
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.studio[0].id
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
      workspace_resource_id = azurerm_log_analytics_workspace.studio[0].id
    }
  }
}
