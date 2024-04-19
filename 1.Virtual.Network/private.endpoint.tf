###############################################################################################
# Private Endpoint (https://learn.microsoft.com/azure/private-link/private-endpoint-overview) #
###############################################################################################

resource azurerm_private_endpoint storage_blob {
  for_each = {
    for subnet in local.virtualNetworksSubnetStorage : subnet.key => subnet
  }
  name                = "${lower(each.value.virtualNetworkName)}-blob"
  resource_group_name = each.value.resourceGroupName
  location            = each.value.regionName
  subnet_id           = "${each.value.virtualNetworkId}/subnets/${each.value.name}"
  private_service_connection {
    name                           = data.azurerm_storage_account.studio.name
    private_connection_resource_id = data.azurerm_storage_account.studio.id
    is_manual_connection           = false
    subresource_names = [
      "blob"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.storage_blob[each.value.virtualNetworkName].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.storage_blob.id
    ]
  }
  depends_on = [
    azurerm_subnet.studio,
    azurerm_subnet_nat_gateway_association.studio,
    azurerm_private_dns_zone_virtual_network_link.storage_blob
 ]
}

resource azurerm_private_endpoint storage_file {
  for_each = {
    for subnet in local.virtualNetworksSubnetStorage : subnet.key => subnet
  }
  name                = "${lower(each.value.virtualNetworkName)}-file"
  resource_group_name = each.value.resourceGroupName
  location            = each.value.regionName
  subnet_id           = "${each.value.virtualNetworkId}/subnets/${each.value.name}"
  private_service_connection {
    name                           = data.azurerm_storage_account.studio.name
    private_connection_resource_id = data.azurerm_storage_account.studio.id
    is_manual_connection           = false
    subresource_names = [
      "file"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.storage_file[each.value.virtualNetworkName].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.storage_file.id
    ]
  }
  depends_on = [
    azurerm_subnet.studio,
    azurerm_private_endpoint.storage_blob,
    azurerm_private_dns_zone_virtual_network_link.storage_file
  ]
}

resource azurerm_private_endpoint search {
  for_each = {
    for subnet in local.virtualNetworksSubnetCompute : subnet.key => subnet if module.global.search.enable
  }
  name                = "${lower(each.value.virtualNetworkName)}-search"
  resource_group_name = each.value.resourceGroupName
  location            = each.value.regionName
  subnet_id           = "${each.value.virtualNetworkId}/subnets/${each.value.name}"
  private_service_connection {
    name                           = data.azurerm_search_service.studio[0].name
    private_connection_resource_id = data.azurerm_search_service.studio[0].id
    is_manual_connection           = false
    subresource_names = [
      "searchService"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.search[each.value.virtualNetworkName].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.search[0].id
    ]
  }
  depends_on = [
    azurerm_subnet.studio,
    azurerm_private_endpoint.storage_file,
    azurerm_private_dns_zone_virtual_network_link.search
  ]
}

resource azurerm_private_endpoint key_vault {
  for_each = {
    for subnet in local.virtualNetworksSubnetStorage : subnet.key => subnet if module.global.keyVault.enable
  }
  name                = "${lower(each.value.virtualNetworkName)}-vault"
  resource_group_name = each.value.resourceGroupName
  location            = each.value.regionName
  subnet_id           = "${each.value.virtualNetworkId}/subnets/${each.value.name}"
  private_service_connection {
    name                           = data.azurerm_key_vault.studio[0].name
    private_connection_resource_id = data.azurerm_key_vault.studio[0].id
    is_manual_connection           = false
    subresource_names = [
      "vault"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.key_vault[each.value.virtualNetworkName].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.key_vault[0].id
    ]
  }
  depends_on = [
    azurerm_subnet.studio,
    azurerm_private_endpoint.search,
    azurerm_private_dns_zone_virtual_network_link.key_vault
  ]
}

resource azurerm_private_endpoint app_config {
  for_each = {
    for subnet in local.virtualNetworksSubnetStorage : subnet.key => subnet if module.global.appConfig.enable
  }
  name                = "${lower(each.value.virtualNetworkName)}-app-config"
  resource_group_name = each.value.resourceGroupName
  location            = each.value.regionName
  subnet_id           = "${each.value.virtualNetworkId}/subnets/${each.value.name}"
  private_service_connection {
    name                           = data.azurerm_app_configuration.studio[0].name
    private_connection_resource_id = data.azurerm_app_configuration.studio[0].id
    is_manual_connection           = false
    subresource_names = [
      "configurationStores"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.app_config[each.value.virtualNetworkName].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.app_config[0].id
    ]
  }
  depends_on = [
    azurerm_subnet.studio,
    azurerm_private_endpoint.key_vault,
    azurerm_private_dns_zone_virtual_network_link.app_config
 ]
}
