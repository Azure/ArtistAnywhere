############################################################################
# Private DNS (https://learn.microsoft.com/azure/dns/private-dns-overview) #
############################################################################

variable privateDNS {
  type = object({
    zoneName = string
    autoRegistration = object({
      enable = bool
    })
  })
}

resource azurerm_role_assignment private_dns_zone_contributor {
  role_definition_name = "Private DNS Zone Contributor" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/networking#private-dns-zone-contributor
  principal_id         = data.azurerm_user_assigned_identity.studio.principal_id
  scope                = azurerm_private_dns_zone.studio.id
}

resource azurerm_private_dns_zone studio {
  name                = var.privateDNS.zoneName
  resource_group_name = azurerm_resource_group.network.name
}

resource azurerm_private_dns_zone_virtual_network_link studio {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.key => virtualNetwork
  }
  name                  = each.value.key
  resource_group_name   = azurerm_private_dns_zone.studio.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.studio.name
  virtual_network_id    = each.value.id
  registration_enabled  = var.privateDNS.autoRegistration.enable
  depends_on = [
    azurerm_virtual_network.studio
  ]
}
