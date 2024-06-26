######################################################################
# Monitor (https://learn.microsoft.com/azure/azure-monitor/overview) #
######################################################################

variable monitor {
  type = object({
    enable = bool
  })
}

data azurerm_log_analytics_workspace studio {
  count               = module.global.monitor.enable && var.monitor.enable ? 1 : 0
  name                = module.global.monitor.name
  resource_group_name = module.global.resourceGroupName
}

data azurerm_application_insights studio {
  count               = module.global.monitor.enable && var.monitor.enable ? 1 : 0
  name                = module.global.monitor.name
  resource_group_name = module.global.resourceGroupName
}

data azurerm_monitor_data_collection_endpoint studio {
  count               = module.global.monitor.enable && var.monitor.enable ? 1 : 0
  name                = module.global.monitor.name
  resource_group_name = module.global.resourceGroupName
}

locals {
  monitorNetworks = [
    for virtualNetwork in local.virtualNetworks: virtualNetwork if module.global.monitor.enable && var.monitor.enable && virtualNetwork.edgeZone == ""
  ]
}

resource azurerm_private_dns_zone monitor {
  count               = module.global.monitor.enable && var.monitor.enable ? 1 : 0
  name                = "privatelink.monitor.azure.com"
  resource_group_name = azurerm_resource_group.network.name
}

resource azurerm_private_dns_zone monitor_opinsights_oms {
  count               = module.global.monitor.enable && var.monitor.enable ? 1 : 0
  name                = "privatelink.oms.opinsights.azure.com"
  resource_group_name = azurerm_resource_group.network.name
}

resource azurerm_private_dns_zone monitor_opinsights_ods {
  count               = module.global.monitor.enable && var.monitor.enable ? 1 : 0
  name                = "privatelink.ods.opinsights.azure.com"
  resource_group_name = azurerm_resource_group.network.name
}

resource azurerm_private_dns_zone monitor_automation {
  count               = module.global.monitor.enable && var.monitor.enable ? 1 : 0
  name                = "privatelink.agentsvc.azure-automation.net"
  resource_group_name = azurerm_resource_group.network.name
}

resource azurerm_private_dns_zone_virtual_network_link monitor {
  for_each = {
    for virtualNetwork in local.monitorNetworks : virtualNetwork.key => virtualNetwork
  }
  name                  = "${lower(each.value.key)}-monitor"
  resource_group_name   = azurerm_private_dns_zone.monitor[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.monitor[0].name
  virtual_network_id    = each.value.id
}

resource azurerm_private_dns_zone_virtual_network_link monitor_opinsights_oms {
  for_each = {
    for virtualNetwork in local.monitorNetworks : virtualNetwork.key => virtualNetwork
  }
  name                  = "${lower(each.value.key)}-monitor-opinsights-oms"
  resource_group_name   = azurerm_private_dns_zone.monitor_opinsights_oms[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.monitor_opinsights_oms[0].name
  virtual_network_id    = each.value.id
}

resource azurerm_private_dns_zone_virtual_network_link monitor_opinsights_ods {
  for_each = {
    for virtualNetwork in local.monitorNetworks : virtualNetwork.key => virtualNetwork
  }
  name                  = "${lower(each.value.key)}-monitor-opinsights-ods"
  resource_group_name   = azurerm_private_dns_zone.monitor_opinsights_ods[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.monitor_opinsights_ods[0].name
  virtual_network_id    = each.value.id
}

resource azurerm_private_dns_zone_virtual_network_link monitor_automation {
  for_each = {
    for virtualNetwork in local.monitorNetworks : virtualNetwork.key => virtualNetwork
  }
  name                  = "${lower(each.value.key)}-monitor-automation"
  resource_group_name   = azurerm_private_dns_zone.monitor_automation[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.monitor_automation[0].name
  virtual_network_id    = each.value.id
}

resource azurerm_private_endpoint monitor {
  for_each = {
    for subnet in local.virtualNetworksSubnetStorage : subnet.key => subnet if module.global.monitor.enable && var.monitor.enable
  }
  name                = "${azurerm_monitor_private_link_scope.monitor[0].name}-monitor"
  resource_group_name = each.value.resourceGroupName
  location            = each.value.regionName
  subnet_id           = "${each.value.virtualNetworkId}/subnets/${each.value.name}"
  private_service_connection {
    name                           = azurerm_monitor_private_link_scope.monitor[0].name
    private_connection_resource_id = azurerm_monitor_private_link_scope.monitor[0].id
    is_manual_connection           = false
    subresource_names = [
      "azuremonitor"
    ]
  }
  private_dns_zone_group {
    name = azurerm_monitor_private_link_scope.monitor[0].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.monitor[0].id,
      azurerm_private_dns_zone.monitor_opinsights_oms[0].id,
      azurerm_private_dns_zone.monitor_opinsights_ods[0].id,
      azurerm_private_dns_zone.monitor_automation[0].id,
      azurerm_private_dns_zone.storage_blob.id
    ]
  }
  depends_on = [
    azurerm_subnet.studio,
    azurerm_private_dns_zone_virtual_network_link.monitor,
    azurerm_private_dns_zone_virtual_network_link.monitor_opinsights_oms,
    azurerm_private_dns_zone_virtual_network_link.monitor_opinsights_ods,
    azurerm_private_dns_zone_virtual_network_link.monitor_automation,
    azurerm_private_endpoint.storage_file
  ]
}

resource azurerm_monitor_private_link_scope monitor {
  count                 = module.global.monitor.enable && var.monitor.enable ? 1 : 0
  name                  = module.global.monitor.name
  resource_group_name   = azurerm_resource_group.network.name
  ingestion_access_mode = "PrivateOnly"
  query_access_mode     = "PrivateOnly"
}

resource azurerm_monitor_private_link_scoped_service monitor_workspace {
  count               = module.global.monitor.enable && var.monitor.enable ? 1 : 0
  name                = "${module.global.monitor.name}-workspace"
  resource_group_name = azurerm_resource_group.network.name
  linked_resource_id  = data.azurerm_log_analytics_workspace.studio[0].id
  scope_name          = azurerm_monitor_private_link_scope.monitor[0].name
}

resource azurerm_monitor_private_link_scoped_service monitor_insight {
  count               = module.global.monitor.enable && var.monitor.enable ? 1 : 0
  name                = "${module.global.monitor.name}-insight"
  resource_group_name = azurerm_resource_group.network.name
  linked_resource_id  = data.azurerm_application_insights.studio[0].id
  scope_name          = azurerm_monitor_private_link_scope.monitor[0].name
}

resource azurerm_monitor_private_link_scoped_service monitor_endpoint {
  count               = module.global.monitor.enable && var.monitor.enable ? 1 : 0
  name                = "${module.global.monitor.name}-data"
  resource_group_name = azurerm_resource_group.network.name
  linked_resource_id  = data.azurerm_monitor_data_collection_endpoint.studio[0].id
  scope_name          = azurerm_monitor_private_link_scope.monitor[0].name
}
