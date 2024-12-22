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

resource azurerm_role_assignment private_dns_zone_contributor {
  role_definition_name = "Private DNS Zone Contributor" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/networking#private-dns-zone-contributor
  principal_id         = data.azurerm_user_assigned_identity.studio.principal_id
  scope                = azurerm_private_dns_zone.studio.id
}

resource azurerm_private_dns_zone studio {
  name                = var.privateDns.zoneName
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
  registration_enabled  = var.privateDns.autoRegistration.enable
  depends_on = [
    azurerm_virtual_network.studio
  ]
}

##############################################################################################
# Private DNS Resolver (https://learn.microsoft.com/azure/dns/dns-private-resolver-overview) #
##############################################################################################

resource azurerm_private_dns_resolver studio {
  name                = local.virtualNetwork.key
  resource_group_name = local.virtualNetwork.resourceGroupName
  location            = local.virtualNetwork.regionName
  virtual_network_id  = local.virtualNetwork.id
  depends_on = [
    azurerm_virtual_network.studio
  ]
}

resource azurerm_private_dns_resolver_inbound_endpoint studio {
  name                    = local.virtualNetwork.key
  location                = local.virtualNetwork.regionName
  private_dns_resolver_id = azurerm_private_dns_resolver.studio.id
  ip_configurations {
    subnet_id = "${local.virtualNetwork.id}/subnets/DNS"
  }
  depends_on = [
    azurerm_subnet.studio
  ]
}

output privateDns {
  value = {
    zoneName          = azurerm_private_dns_zone.studio.name
    resourceGroupName = azurerm_private_dns_zone.studio.resource_group_name
    resolver = {
      ipAddresses = azurerm_private_dns_resolver_inbound_endpoint.studio[*].ip_configurations[0].private_ip_address
    }
  }
}
