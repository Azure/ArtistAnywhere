############################################################################
# Private DNS (https://learn.microsoft.com/azure/dns/private-dns-overview) #
############################################################################

variable privateDns {
  type = object({
    zoneName = string
    autoRegistration = object({
      enable = bool
    })
  })
}

resource azurerm_private_dns_zone studio {
  name                = var.privateDns.zoneName
  resource_group_name = azurerm_resource_group.network.name
}

resource azurerm_private_dns_zone_virtual_network_link studio {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.name => virtualNetwork if virtualNetwork.edgeZone == ""
  }
  name                  = each.value.name
  resource_group_name   = azurerm_private_dns_zone.studio.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.studio.name
  virtual_network_id    = each.value.id
  registration_enabled  = var.privateDns.autoRegistration.enable
  depends_on = [
    azurerm_virtual_network.studio
  ]
}

output privateDns {
  value = {
    name              = azurerm_private_dns_zone.studio.name
    resourceGroupName = azurerm_private_dns_zone.studio.resource_group_name
  }
}
