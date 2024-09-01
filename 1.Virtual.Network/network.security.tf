########################################################################################################################
# Virtual Network Security Groups (https://learn.microsoft.com/azure/virtual-network/network-security-groups-overview) #
########################################################################################################################

resource azurerm_network_security_group studio {
  for_each = {
    for subnet in local.virtualNetworksSubnetsSecurity : subnet.key => subnet if subnet.name != "AzureBastionSubnet"
  }
  name                = "${each.value.virtualNetworkName}-${each.value.name}"
  resource_group_name = each.value.resourceGroupName
  location            = each.value.regionName
  security_rule {
    name                       = "AllowOutARM"
    priority                   = 3200
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
    priority                   = 3100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "Storage"
    destination_port_range     = "*"
  }
  dynamic security_rule {
    for_each = each.value.name == "Workstation" ? [1] : []
    content {
      name                       = "AllowInPCoIP.TCP"
      priority                   = 2000
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
    for_each = each.value.name == "Workstation" ? [1] : []
    content {
      name                       = "AllowInPCoIP.UDP"
      priority                   = 2100
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
    azurerm_virtual_network.studio
  ]
}

resource azurerm_subnet_network_security_group_association studio {
  for_each = {
    for subnet in local.virtualNetworksSubnetsSecurity : subnet.key => subnet if subnet.name != "AzureBastionSubnet" && subnet.virtualNetworkExtendedZone == ""
  }
  subnet_id                 = "${each.value.virtualNetworkId}/subnets/${each.value.name}"
  network_security_group_id = azurerm_network_security_group.studio[each.value.key].id
  depends_on = [
    azurerm_subnet.studio,
    azurerm_network_security_group.studio
  ]
}
