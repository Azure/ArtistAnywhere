######################################################################
# Monitor (https://learn.microsoft.com/azure/azure-monitor/overview) #
######################################################################

locals {
  monitorNetworks = [
    for virtualNetwork in local.virtualNetworks: virtualNetwork if try(virtualNetwork.extendedZone.name, "") == ""
  ]
}

resource azurerm_private_dns_zone monitor {
  name                = "privatelink.monitor.azure.com"
  resource_group_name = azurerm_resource_group.network.name
}

resource azurerm_private_dns_zone monitor_opinsights_oms {
  name                = "privatelink.oms.opinsights.azure.com"
  resource_group_name = azurerm_resource_group.network.name
}

resource azurerm_private_dns_zone monitor_opinsights_ods {
  name                = "privatelink.ods.opinsights.azure.com"
  resource_group_name = azurerm_resource_group.network.name
}

resource azurerm_private_dns_zone monitor_automation {
  name                = "privatelink.agentsvc.azure-automation.net"
  resource_group_name = azurerm_resource_group.network.name
}

resource azurerm_private_dns_zone_virtual_network_link monitor {
  for_each = {
    for virtualNetwork in local.monitorNetworks : virtualNetwork.key => virtualNetwork
  }
  name                  = "${lower(each.value.key)}-monitor"
  resource_group_name   = azurerm_private_dns_zone.monitor.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.monitor.name
  virtual_network_id    = each.value.id
  depends_on = [
    azurerm_virtual_network.main
  ]
}

resource azurerm_private_dns_zone_virtual_network_link monitor_opinsights_oms {
  for_each = {
    for virtualNetwork in local.monitorNetworks : virtualNetwork.key => virtualNetwork
  }
  name                  = "${lower(each.value.key)}-monitor-opinsights-oms"
  resource_group_name   = azurerm_private_dns_zone.monitor_opinsights_oms.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.monitor_opinsights_oms.name
  virtual_network_id    = each.value.id
  depends_on = [
    azurerm_virtual_network.main
  ]
}

resource azurerm_private_dns_zone_virtual_network_link monitor_opinsights_ods {
  for_each = {
    for virtualNetwork in local.monitorNetworks : virtualNetwork.key => virtualNetwork
  }
  name                  = "${lower(each.value.key)}-monitor-opinsights-ods"
  resource_group_name   = azurerm_private_dns_zone.monitor_opinsights_ods.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.monitor_opinsights_ods.name
  virtual_network_id    = each.value.id
  depends_on = [
    azurerm_virtual_network.main
  ]
}

resource azurerm_private_dns_zone_virtual_network_link monitor_automation {
  for_each = {
    for virtualNetwork in local.monitorNetworks : virtualNetwork.key => virtualNetwork
  }
  name                  = "${lower(each.value.key)}-monitor-automation"
  resource_group_name   = azurerm_private_dns_zone.monitor_automation.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.monitor_automation.name
  virtual_network_id    = each.value.id
  depends_on = [
    azurerm_virtual_network.main
  ]
}

resource azurerm_private_endpoint monitor {
  for_each = {
    for virtualNetwork in local.monitorNetworks : virtualNetwork.key => virtualNetwork
  }
  name                = "${azurerm_monitor_private_link_scope.monitor.name}-monitor"
  resource_group_name = each.value.resourceGroup.name
  location            = each.value.resourceGroup.location
  subnet_id           = "${each.value.id}/subnets/Storage"
  private_service_connection {
    name                           = azurerm_monitor_private_link_scope.monitor.name
    private_connection_resource_id = azurerm_monitor_private_link_scope.monitor.id
    is_manual_connection           = false
    subresource_names = [
      "azuremonitor"
    ]
  }
  private_dns_zone_group {
    name = azurerm_monitor_private_link_scope.monitor.name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.monitor.id,
      azurerm_private_dns_zone.monitor_opinsights_oms.id,
      azurerm_private_dns_zone.monitor_opinsights_ods.id,
      azurerm_private_dns_zone.monitor_automation.id,
      azurerm_private_dns_zone.storage_blob.id
    ]
  }
  depends_on = [
    azurerm_subnet.main,
    azurerm_private_dns_zone_virtual_network_link.monitor,
    azurerm_private_dns_zone_virtual_network_link.monitor_opinsights_oms,
    azurerm_private_dns_zone_virtual_network_link.monitor_opinsights_ods,
    azurerm_private_dns_zone_virtual_network_link.monitor_automation,
    azurerm_private_endpoint.storage_file
  ]
}

resource azurerm_monitor_private_link_scope monitor {
  name                  = data.terraform_remote_state.foundation.outputs.monitor.workspace.name
  resource_group_name   = data.terraform_remote_state.foundation.outputs.monitor.resourceGroup.name
  ingestion_access_mode = "PrivateOnly"
  query_access_mode     = "PrivateOnly"
}

resource azurerm_monitor_private_link_scoped_service monitor_log_analytics {
  name                = "${data.terraform_remote_state.foundation.outputs.monitor.workspace.name}-log-analytics"
  resource_group_name = data.terraform_remote_state.foundation.outputs.monitor.resourceGroup.name
  linked_resource_id  = data.terraform_remote_state.foundation.outputs.monitor.logAnalytics.id
  scope_name          = azurerm_monitor_private_link_scope.monitor.name
}

resource azurerm_monitor_private_link_scoped_service monitor_app_insights {
  name                = "${data.terraform_remote_state.foundation.outputs.monitor.workspace.name}-app-insights"
  resource_group_name = data.terraform_remote_state.foundation.outputs.monitor.resourceGroup.name
  linked_resource_id  = data.terraform_remote_state.foundation.outputs.monitor.applicationInsights.id
  scope_name          = azurerm_monitor_private_link_scope.monitor.name
}

resource azurerm_monitor_private_link_scoped_service monitor_workspace_data {
  name                = "${data.azurerm_monitor_workspace.main.name}-workspace-data"
  resource_group_name = data.azurerm_monitor_workspace.main.resource_group_name
  linked_resource_id  = data.azurerm_monitor_workspace.main.default_data_collection_endpoint_id
  scope_name          = azurerm_monitor_private_link_scope.monitor.name
}
