##################################################################
# Firewall (https://learn.microsoft.com/azure/firewall/overview) #
##################################################################

variable firewall {
  type = object({
    enable = bool
    name   = string
    tier   = string
  })
}

# resource azurerm_public_ip main {
#   for_each = {
#     for virtualNetwork in local.virtualNetworks : virtualNetwork.key => virtualNetwork if var.firewall.enable
#   }
#   name                = var.firewall.name
#   resource_group_name = each.value.resourceGroup.name
#   location            = each.value.location
#   sku                 = "Standard"
#   allocation_method   = "Static"
#   depends_on = [
#     azurerm_resource_group.network_regions
#   ]
# }

resource azurerm_firewall main {
  for_each = {
    for hub in var.virtualWAN.hubs : hub.name => hub if var.virtualWAN.enable && var.firewall.enable && hub.enable
  }
  name                = "${var.firewall.name}-${each.value.name}"
  resource_group_name = azurerm_virtual_wan.main[0].resource_group_name
  location            = each.value.location
  sku_tier            = var.firewall.tier
  sku_name            = "AZFW_Hub"
  virtual_hub {
    virtual_hub_id = azurerm_virtual_hub.main[each.value.name].id
  }
  # ip_configuration {
  #   name      = "ipConfig"
  #   subnet_id = "${each.value.id}/subnets/AzureFirewallSubnet"
  # }
  # management_ip_configuration {
  #   name                 = "ipConfigManagement"
  #   subnet_id            = "${each.value.id}/subnets/AzureFirewallManagementSubnet"
  #   public_ip_address_id = azurerm_public_ip.main[each.value.key].id
  # }
  # depends_on = [
  #   azurerm_subnet_network_security_group_association.main
  # ]
}
