###############################################################################################
# Private Endpoint (https://learn.microsoft.com/azure/private-link/private-endpoint-overview) #
###############################################################################################

resource azurerm_private_dns_zone key_vault {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.network.name
}

resource azurerm_private_dns_zone storage_blob {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.network.name
}

resource azurerm_private_dns_zone storage_file {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = azurerm_resource_group.network.name
}

resource azurerm_private_dns_zone_virtual_network_link key_vault {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.name => virtualNetwork
  }
  name                  = "key-vault-${lower(each.value.regionName)}"
  resource_group_name   = azurerm_resource_group.network.name
  private_dns_zone_name = azurerm_private_dns_zone.key_vault.name
  virtual_network_id    = each.value.id
  depends_on = [
    azurerm_virtual_network.studio
  ]
}

resource azurerm_private_dns_zone_virtual_network_link storage_blob {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.name => virtualNetwork
  }
  name                  = "storage-blob-${lower(each.value.regionName)}"
  resource_group_name   = azurerm_resource_group.network.name
  private_dns_zone_name = azurerm_private_dns_zone.storage_blob.name
  virtual_network_id    = each.value.id
  depends_on = [
    azurerm_virtual_network.studio
  ]
}

resource azurerm_private_dns_zone_virtual_network_link storage_file {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.name => virtualNetwork
  }
  name                  = "storage-file-${lower(each.value.regionName)}"
  resource_group_name   = azurerm_resource_group.network.name
  private_dns_zone_name = azurerm_private_dns_zone.storage_file.name
  virtual_network_id    = each.value.id
  depends_on = [
    azurerm_virtual_network.studio
  ]
}

resource azurerm_private_endpoint key_vault {
  for_each = {
    for subnet in local.virtualNetworksSubnetStorage : "${subnet.virtualNetworkName}-${subnet.name}" => subnet
  }
  name                = "${data.azurerm_key_vault.studio.name}-vault"
  resource_group_name = each.value.resourceGroupName
  location            = each.value.regionName
  subnet_id           = "${each.value.virtualNetworkId}/subnets/${each.value.name}"
  private_service_connection {
    name                           = data.azurerm_key_vault.studio.name
    private_connection_resource_id = data.azurerm_key_vault.studio.id
    is_manual_connection           = false
    subresource_names = [
      "vault"
    ]
  }
  private_dns_zone_group {
    name = data.azurerm_key_vault.studio.name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.key_vault.id
    ]
  }
  depends_on = [
    azurerm_subnet.studio,
    azurerm_private_dns_zone_virtual_network_link.key_vault,
    azurerm_subnet_nat_gateway_association.studio
  ]
}

resource azurerm_private_endpoint storage_blob {
  for_each = {
    for subnet in local.virtualNetworksSubnetStorage : "${subnet.virtualNetworkName}-${subnet.name}" => subnet
  }
  name                = "${data.azurerm_storage_account.studio.name}-blob"
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
    name = data.azurerm_storage_account.studio.name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.storage_blob.id
    ]
  }
  depends_on = [
    azurerm_subnet.studio,
    azurerm_private_endpoint.key_vault,
    azurerm_private_dns_zone_virtual_network_link.storage_blob
 ]
}

resource azurerm_private_endpoint storage_file {
  for_each = {
    for subnet in local.virtualNetworksSubnetStorage : "${subnet.virtualNetworkName}-${subnet.name}" => subnet
  }
  name                = "${data.azurerm_storage_account.studio.name}-file"
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
    name = data.azurerm_storage_account.studio.name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.storage_file.id
    ]
  }
  depends_on = [
    azurerm_subnet.studio,
    azurerm_private_dns_zone_virtual_network_link.storage_file,
    azurerm_private_endpoint.storage_blob
  ]
}
