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

resource azurerm_private_dns_zone app_config {
  count               = module.global.appConfig.enable ? 1 : 0
  name                = "privatelink.azconfig.io"
  resource_group_name = azurerm_resource_group.network.name
}

resource azurerm_private_dns_zone_virtual_network_link storage_blob {
  for_each = {
    for virtualNetwork in local.virtualNetworksExtended : virtualNetwork.key => virtualNetwork
  }
  name                  = "${lower(each.value.key)}-storage-blob"
  resource_group_name   = azurerm_private_dns_zone.storage_blob.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.storage_blob.name
  virtual_network_id    = each.value.id
  depends_on = [
    azurerm_virtual_network.studio
  ]
}

resource azurerm_private_dns_zone_virtual_network_link storage_file {
  for_each = {
    for virtualNetwork in local.virtualNetworksExtended : virtualNetwork.key => virtualNetwork
  }
  name                  = "${lower(each.value.key)}-storage-file"
  resource_group_name   = azurerm_private_dns_zone.storage_file.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.storage_file.name
  virtual_network_id    = each.value.id
  depends_on = [
    azurerm_virtual_network.studio
  ]
}

resource azurerm_private_dns_zone_virtual_network_link search {
  for_each = {
    for virtualNetwork in local.virtualNetworksExtended : virtualNetwork.key => virtualNetwork if module.global.search.enable
  }
  name                  = "${lower(each.value.key)}-search"
  resource_group_name   = azurerm_private_dns_zone.search[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.search[0].name
  virtual_network_id    = each.value.id
  depends_on = [
    azurerm_virtual_network.studio
  ]
}

resource azurerm_private_dns_zone_virtual_network_link key_vault {
  for_each = {
    for virtualNetwork in local.virtualNetworksExtended : virtualNetwork.key => virtualNetwork if module.global.keyVault.enable
  }
  name                  = "${lower(each.value.key)}-key-vault"
  resource_group_name   = azurerm_private_dns_zone.key_vault[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.key_vault[0].name
  virtual_network_id    = each.value.id
  depends_on = [
    azurerm_virtual_network.studio
  ]
}

resource azurerm_private_dns_zone_virtual_network_link app_config {
  for_each = {
    for virtualNetwork in local.virtualNetworksExtended : virtualNetwork.key => virtualNetwork if module.global.appConfig.enable
  }
  name                  = "${lower(each.value.key)}-app-config"
  resource_group_name   = azurerm_private_dns_zone.app_config[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.app_config[0].name
  virtual_network_id    = each.value.id
  depends_on = [
    azurerm_virtual_network.studio
  ]
}
