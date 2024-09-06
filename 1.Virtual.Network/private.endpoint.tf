###############################################################################################
# Private Endpoint (https://learn.microsoft.com/azure/private-link/private-endpoint-overview) #
###############################################################################################

resource azurerm_private_endpoint storage_blob {
  name                = "${lower(data.azurerm_storage_account.studio.name)}-blob"
  resource_group_name = data.azurerm_storage_account.studio.resource_group_name
  location            = data.azurerm_storage_account.studio.location
  subnet_id           = "${local.virtualNetwork.id}/subnets/Storage"
  private_service_connection {
    name                           = data.azurerm_storage_account.studio.name
    private_connection_resource_id = data.azurerm_storage_account.studio.id
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
    azurerm_subnet.studio,
    azurerm_subnet_nat_gateway_association.studio
 ]
}

resource azurerm_private_endpoint storage_file {
  name                = "${lower(data.azurerm_storage_account.studio.name)}-file"
  resource_group_name = data.azurerm_storage_account.studio.resource_group_name
  location            = data.azurerm_storage_account.studio.location
  subnet_id           = "${local.virtualNetwork.id}/subnets/Storage"
  private_service_connection {
    name                           = data.azurerm_storage_account.studio.name
    private_connection_resource_id = data.azurerm_storage_account.studio.id
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
    azurerm_subnet.studio,
    azurerm_private_endpoint.storage_blob
  ]
}

resource azurerm_private_endpoint key_vault {
  name                = "${lower(data.azurerm_key_vault.studio.name)}-key-vault"
  resource_group_name = data.azurerm_key_vault.studio.resource_group_name
  location            = data.azurerm_key_vault.studio.location
  subnet_id           = "${local.virtualNetwork.id}/subnets/Storage"
  private_service_connection {
    name                           = data.azurerm_key_vault.studio.name
    private_connection_resource_id = data.azurerm_key_vault.studio.id
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
    azurerm_subnet.studio,
    azurerm_private_endpoint.storage_file
  ]
}

resource azurerm_private_endpoint app_config {
  name                = "${lower(data.azurerm_app_configuration.studio.name)}-app-config"
  resource_group_name = data.azurerm_app_configuration.studio.resource_group_name
  location            = data.azurerm_app_configuration.studio.location
  subnet_id           = "${local.virtualNetwork.id}/subnets/Storage"
  private_service_connection {
    name                           = data.azurerm_app_configuration.studio.name
    private_connection_resource_id = data.azurerm_app_configuration.studio.id
    is_manual_connection           = false
    subresource_names = [
      "configurationStores"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.app_config.name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.app_config.id
    ]
  }
  depends_on = [
    azurerm_subnet.studio,
    azurerm_private_endpoint.key_vault
 ]
}

output keyVaultPrivateEndpointId {
  value = azurerm_private_endpoint.key_vault.id
}
