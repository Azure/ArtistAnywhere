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
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.network.name
}

resource azurerm_private_dns_zone grafana {
  name                = "privatelink.grafana.azure.com"
  resource_group_name = azurerm_resource_group.network.name
}

# resource azurerm_private_dns_zone app_config {
#   name                = "privatelink.azconfig.io"
#   resource_group_name = azurerm_resource_group.network.name
# }

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
  name                  = "key-vault"
  resource_group_name   = azurerm_private_dns_zone.key_vault.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.key_vault.name
  virtual_network_id    = local.virtualNetwork.id
  depends_on = [
    azurerm_virtual_network.studio
  ]
}

resource azurerm_private_dns_zone_virtual_network_link grafana {
  name                  = "grafana"
  resource_group_name   = azurerm_private_dns_zone.grafana.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.grafana.name
  virtual_network_id    = local.virtualNetwork.id
  depends_on = [
    azurerm_virtual_network.studio
  ]
}

# resource azurerm_private_dns_zone_virtual_network_link app_config {
#   name                  = "app-config"
#   resource_group_name   = azurerm_private_dns_zone.app_config.resource_group_name
#   private_dns_zone_name = azurerm_private_dns_zone.app_config.name
#   virtual_network_id    = local.virtualNetwork.id
#   depends_on = [
#     azurerm_virtual_network.studio
#   ]
# }
