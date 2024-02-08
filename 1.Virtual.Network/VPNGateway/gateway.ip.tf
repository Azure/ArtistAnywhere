######################################################################################################################
# Public IP Address Prefix (https://learn.microsoft.com/azure/virtual-network/ip-services/public-ip-address-prefix ) #
# Public IP Addresses      (https://learn.microsoft.com/azure/virtual-network/ip-services/public-ip-addresses)       #
######################################################################################################################

resource azurerm_public_ip_prefix vpn_gateway {
  name                = "Gateway-VPN"
  resource_group_name = azurerm_resource_group.network.name
  location            = azurerm_resource_group.network.location
  prefix_length       = 31
  lifecycle { # Ensures on-premises VPN device IP address configuration stays aligned with Azure
    prevent_destroy = true
  }
}

resource azurerm_public_ip vpn_gateway_1 {
  name                = var.vpnGateway.enableActiveActive ? "${azurerm_public_ip_prefix.vpn_gateway.name}1" : azurerm_public_ip_prefix.vpn_gateway.name
  resource_group_name = azurerm_resource_group.network.name
  location            = azurerm_resource_group.network.location
  public_ip_prefix_id = azurerm_public_ip_prefix.vpn_gateway.id
  sku                 = "Standard"
  allocation_method   = "Static"
}

resource azurerm_public_ip vpn_gateway_2 {
  name                = "${azurerm_public_ip_prefix.vpn_gateway.name}2"
  resource_group_name = azurerm_resource_group.network.name
  location            = azurerm_resource_group.network.location
  public_ip_prefix_id = azurerm_public_ip_prefix.vpn_gateway.id
  sku                 = "Standard"
  allocation_method   = "Static"
}
