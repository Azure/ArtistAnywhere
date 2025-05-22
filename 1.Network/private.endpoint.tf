###############################################################################################
# Private Endpoint (https://learn.microsoft.com/azure/private-link/private-endpoint-overview) #
###############################################################################################

resource azurerm_private_endpoint storage_blob {
  name                = "${lower(data.azurerm_storage_account.main.name)}-${azurerm_private_dns_zone_virtual_network_link.storage_blob.name}"
  resource_group_name = data.azurerm_storage_account.main.resource_group_name
  location            = data.azurerm_storage_account.main.location
  subnet_id           = "${local.virtualNetwork.id}/subnets/Storage"
  private_service_connection {
    name                           = data.azurerm_storage_account.main.name
    private_connection_resource_id = data.azurerm_storage_account.main.id
    is_manual_connection           = false
    subresource_names = [
      "blob"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.storage_blob.name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.storage_blob.id
    ]
  }
  depends_on = [
    azurerm_subnet.main,
    azurerm_subnet_nat_gateway_association.main
  ]
}

resource azurerm_private_endpoint storage_file {
  name                = "${lower(data.azurerm_storage_account.main.name)}-${azurerm_private_dns_zone_virtual_network_link.storage_file.name}"
  resource_group_name = data.azurerm_storage_account.main.resource_group_name
  location            = data.azurerm_storage_account.main.location
  subnet_id           = "${local.virtualNetwork.id}/subnets/Storage"
  private_service_connection {
    name                           = data.azurerm_storage_account.main.name
    private_connection_resource_id = data.azurerm_storage_account.main.id
    is_manual_connection           = false
    subresource_names = [
      "file"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.storage_file.name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.storage_file.id
    ]
  }
  depends_on = [
    azurerm_private_endpoint.storage_blob
  ]
}

resource azurerm_private_endpoint key_vault {
  name                = "${lower(data.azurerm_key_vault.main.name)}-${azurerm_private_dns_zone_virtual_network_link.key_vault.name}"
  resource_group_name = data.azurerm_key_vault.main.resource_group_name
  location            = data.azurerm_key_vault.main.location
  subnet_id           = "${local.virtualNetwork.id}/subnets/Storage"
  private_service_connection {
    name                           = data.azurerm_key_vault.main.name
    private_connection_resource_id = data.azurerm_key_vault.main.id
    is_manual_connection           = false
    subresource_names = [
      "vault"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.key_vault.name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.key_vault.id
    ]
  }
  depends_on = [
    azurerm_private_endpoint.storage_file
  ]
}

resource azurerm_private_endpoint monitor_workspace {
  name                = "${lower(data.azurerm_monitor_workspace.main.name)}-${azurerm_private_dns_zone_virtual_network_link.monitor_workspace.name}"
  resource_group_name = data.azurerm_monitor_workspace.main.resource_group_name
  location            = data.azurerm_monitor_workspace.main.location
  subnet_id           = "${local.virtualNetwork.id}/subnets/Storage"
  private_service_connection {
    name                           = data.azurerm_monitor_workspace.main.name
    private_connection_resource_id = data.azurerm_monitor_workspace.main.id
    is_manual_connection           = false
    subresource_names = [
      "prometheusMetrics"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.monitor_workspace.name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.monitor_workspace.id
    ]
  }
  depends_on = [
    azurerm_private_endpoint.key_vault
  ]
}

resource azurerm_private_endpoint grafana {
  name                = "${lower(data.azurerm_dashboard_grafana.main.name)}-${azurerm_private_dns_zone_virtual_network_link.grafana.name}"
  resource_group_name = data.azurerm_dashboard_grafana.main.resource_group_name
  location            = data.azurerm_dashboard_grafana.main.location
  subnet_id           = "${local.virtualNetwork.id}/subnets/Storage"
  private_service_connection {
    name                           = data.azurerm_dashboard_grafana.main.name
    private_connection_resource_id = data.azurerm_dashboard_grafana.main.id
    is_manual_connection           = false
    subresource_names = [
      "grafana"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.grafana.name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.grafana.id
    ]
  }
  depends_on = [
    azurerm_private_endpoint.monitor_workspace
  ]
}

# resource azurerm_private_endpoint app_config {
#   name                = "${lower(data.azurerm_app_configuration.main.name)}-${azurerm_private_dns_zone_virtual_network_link.app_config.name}"
#   resource_group_name = data.azurerm_key_vault.main.resource_group_name
#   location            = data.azurerm_key_vault.main.location
#   subnet_id           = "${local.virtualNetwork.id}/subnets/Storage"
#   private_service_connection {
#     name                           = data.azurerm_app_configuration.main.name
#     private_connection_resource_id = data.azurerm_app_configuration.main.id
#     is_manual_connection           = false
#     subresource_names = [
#       "configurationStores"
#     ]
#   }
#   private_dns_zone_group {
#     name = azurerm_private_dns_zone_virtual_network_link.app_config.name
#     private_dns_zone_ids = [
#       azurerm_private_dns_zone.app_config.id
#     ]
#   }
#   depends_on = [
#     azurerm_private_endpoint.grafana
#   ]
# }
