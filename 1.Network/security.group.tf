########################################################################################################################
# Virtual Network Security Groups (https://learn.microsoft.com/azure/virtual-network/network-security-groups-overview) #
########################################################################################################################

resource azurerm_network_security_group main {
  for_each = {
    for subnet in local.virtualNetworksSubnetsSecurity : subnet.key => subnet if subnet.name != "AzureBastionSubnet"
  }
  name                = "${each.value.virtualNetwork.name}-${each.value.name}"
  resource_group_name = each.value.resourceGroup.name
  location            = each.value.location
  security_rule {
    name                       = "AllowOutARM"
    priority                   = 3100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "AzureResourceManager"
    destination_port_range     = "*"
  }
  security_rule {
    name                       = "AllowOutStorage"
    priority                   = 3000
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "Storage"
    destination_port_range     = "*"
  }
  dynamic security_rule {
    for_each = each.value.name == "VDI" ? [1] : []
    content {
      name                       = "AllowInPCoIP.TCP"
      priority                   = 2100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_address_prefix      = "Internet"
      source_port_range          = "*"
      destination_address_prefix = "*"
      destination_port_ranges = [
        "443",
        "4172",
        "60433"
      ]
    }
  }
  dynamic security_rule {
    for_each = each.value.name == "VDI" ? [1] : []
    content {
      name                       = "AllowInPCoIP.UDP"
      priority                   = 2000
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Udp"
      source_address_prefix      = "Internet"
      source_port_range          = "*"
      destination_address_prefix = "*"
      destination_port_range     = "4172"
    }
  }
  depends_on = [
    azurerm_virtual_network.main
  ]
}

resource azurerm_subnet_network_security_group_association main {
  for_each = {
    for subnet in local.virtualNetworksSubnetsSecurity : subnet.key => subnet if subnet.name != "AzureBastionSubnet"
  }
  subnet_id                 = "${each.value.virtualNetwork.id}/subnets/${each.value.name}"
  network_security_group_id = azurerm_network_security_group.main[each.value.key].id
  depends_on = [
    azurerm_subnet.main
  ]
}
