#######################################################################################
# Private Link (https://learn.microsoft.com/azure/private-link/private-link-overview) #
#######################################################################################

resource azurerm_private_dns_zone storage_blob {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.network.name
}

resource azurerm_private_dns_zone storage_file {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = azurerm_resource_group.network.name
}

resource azurerm_private_dns_zone search {
  count               = module.global.search.enable ? 1 : 0
  name                = "privatelink.search.windows.net"
  resource_group_name = azurerm_resource_group.network.name
}

resource azurerm_private_dns_zone key_vault {
  count               = module.global.keyVault.enable ? 1 : 0
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.network.name
}

resource azurerm_private_dns_zone_virtual_network_link storage_blob {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.name => virtualNetwork
  }
  name                  = "${lower(each.value.name)}-storage-blob"
  resource_group_name   = azurerm_private_dns_zone.storage_blob.resource_group_name
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
  name                  = "${lower(each.value.name)}-storage-file"
  resource_group_name   = azurerm_private_dns_zone.storage_file.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.storage_file.name
  virtual_network_id    = each.value.id
  depends_on = [
    azurerm_virtual_network.studio
  ]
}

resource azurerm_private_dns_zone_virtual_network_link search {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.name => virtualNetwork if module.global.search.enable
  }
  name                  = "${lower(each.value.name)}-search"
  resource_group_name   = azurerm_private_dns_zone.search[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.search[0].name
  virtual_network_id    = each.value.id
  depends_on = [
    azurerm_virtual_network.studio
  ]
}

resource azurerm_private_dns_zone_virtual_network_link key_vault {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.name => virtualNetwork if module.global.keyVault.enable
  }
  name                  = "${lower(each.value.name)}-key-vault"
  resource_group_name   = azurerm_private_dns_zone.key_vault[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.key_vault[0].name
  virtual_network_id    = each.value.id
  depends_on = [
    azurerm_virtual_network.studio
  ]
}