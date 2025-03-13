##################################################################
# Firewall (https://learn.microsoft.com/azure/firewall/overview) #
##################################################################

variable firewall {
  type = object({
    enable = bool
    name   = string
    type   = string
    tier   = string
  })
}

resource azurerm_public_ip studio {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.key => virtualNetwork if var.firewall.enable
  }
  name                = var.firewall.name
  resource_group_name = each.value.resourceGroup.name
  location            = each.value.location
  sku                 = "Standard"
  allocation_method   = "Static"
  depends_on = [
    azurerm_resource_group.network_regions
  ]
}

resource azurerm_firewall studio {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.key => virtualNetwork if var.firewall.enable
  }
  name                = var.firewall.name
  resource_group_name = each.value.resourceGroup.name
  location            = each.value.location
  sku_name            = var.firewall.type
  sku_tier            = var.firewall.tier
  ip_configuration {
    name      = "ipConfig"
    subnet_id = "${each.value.id}/subnets/AzureFirewallSubnet"
  }
  management_ip_configuration {
    name                 = "ipConfigManagement"
    subnet_id            = "${each.value.id}/subnets/AzureFirewallManagementSubnet"
    public_ip_address_id = azurerm_public_ip.studio[each.value.key].id
  }
  depends_on = [
    azurerm_subnet_network_security_group_association.studio
  ]
}
