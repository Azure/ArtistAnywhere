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

resource azurerm_private_dns_zone key_vault {
  count               = module.global.keyVault.enable ? 1 : 0
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.network.name
}

resource azurerm_private_dns_zone event_grid {
  count               = module.global.eventGrid.enable ? 1 : 0
  name                = "privatelink.eventgrid.azure.net"
  resource_group_name = azurerm_resource_group.network.name
}

resource azurerm_private_dns_zone app_config {
  count               = module.global.appConfig.enable ? 1 : 0
  name                = "privatelink.azconfig.io"
  resource_group_name = azurerm_resource_group.network.name
}

resource azurerm_private_dns_zone_virtual_network_link storage_blob {
  name                  = "storage-blob"
  resource_group_name   = azurerm_private_dns_zone.storage_blob.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.storage_blob.name
  virtual_network_id    = local.virtualNetwork.id
  depends_on = [
    azurerm_virtual_network.studio
  ]
}

resource azurerm_private_dns_zone_virtual_network_link storage_file {
  name                  = "storage-file"
  resource_group_name   = azurerm_private_dns_zone.storage_file.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.storage_file.name
  virtual_network_id    = local.virtualNetwork.id
  depends_on = [
    azurerm_virtual_network.studio
  ]
}

resource azurerm_private_dns_zone_virtual_network_link key_vault {
  count                 = module.global.keyVault.enable ? 1 : 0
  name                  = "key-vault"
  resource_group_name   = azurerm_private_dns_zone.key_vault[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.key_vault[0].name
  virtual_network_id    = local.virtualNetwork.id
  depends_on = [
    azurerm_virtual_network.studio
  ]
}

resource azurerm_private_dns_zone_virtual_network_link event_grid {
  count                 = module.global.eventGrid.enable ? 1 : 0
  name                  = "event-grid"
  resource_group_name   = azurerm_private_dns_zone.event_grid[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.event_grid[0].name
  virtual_network_id    = local.virtualNetwork.id
  depends_on = [
    azurerm_virtual_network.studio
  ]
}

resource azurerm_private_dns_zone_virtual_network_link app_config {
  count                 = module.global.appConfig.enable ? 1 : 0
  name                  = "app-config"
  resource_group_name   = azurerm_private_dns_zone.app_config[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.app_config[0].name
  virtual_network_id    = local.virtualNetwork.id
  depends_on = [
    azurerm_virtual_network.studio
  ]
}
