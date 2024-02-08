#################################################################################################
# Virtual Network (https://learn.microsoft.com/azure/virtual-network/virtual-networks-overview) #
#################################################################################################

variable virtualNetworks {
  type = list(object({
    enable       = bool
    name         = string
    nameSuffix   = string
    regionName   = string
    addressSpace = list(string)
    dnsAddresses = list(string)
    subnets = list(object({
      name              = string
      addressSpace      = list(string)
      serviceEndpoints  = list(string)
      serviceDelegation = string
    }))
  }))
}

locals {
  virtualNetwork = local.virtualNetworks[0]
  virtualNetworks = [
    for virtualNetwork in local.virtualNetworksNames : merge(virtualNetwork, {
      id              = "/subscriptions/${data.azurerm_client_config.studio.subscription_id}/resourceGroups/${virtualNetwork.resourceGroupName}/providers/Microsoft.Network/virtualNetworks/${virtualNetwork.name}"
      resourceGroupId = "/subscriptions/${data.azurerm_client_config.studio.subscription_id}/resourceGroups/${virtualNetwork.resourceGroupName}"
    })
  ]
  virtualNetworksNames = [
    for virtualNetwork in var.virtualNetworks : merge(virtualNetwork, {
      regionName        = virtualNetwork.regionName != "" ? virtualNetwork.regionName : module.global.regionName
      name              = virtualNetwork.nameSuffix != "" ? "${virtualNetwork.name}-${virtualNetwork.nameSuffix}" : virtualNetwork.name
      resourceGroupName = virtualNetwork.nameSuffix != "" ? "${var.resourceGroupName}.${virtualNetwork.nameSuffix}" : var.resourceGroupName
    }) if virtualNetwork.enable
  ]
  virtualNetworksSubnets = flatten([
    for virtualNetwork in local.virtualNetworks : [
      for subnet in virtualNetwork.subnets : merge(subnet, {
        regionName         = virtualNetwork.regionName
        resourceGroupId    = virtualNetwork.resourceGroupId
        resourceGroupName  = virtualNetwork.resourceGroupName
        virtualNetworkId   = virtualNetwork.id
        virtualNetworkName = virtualNetwork.name
      })
    ]
  ])
  virtualNetworksSubnetStorage = [
    for subnet in local.virtualNetworksSubnets : subnet if subnet.name == "Storage"
  ]
  virtualNetworksSubnetsSecurity = [
    for subnet in local.virtualNetworksSubnets : subnet if subnet.name != "GatewaySubnet" && subnet.name != "AzureBastionSubnet"
  ]
}

resource azurerm_virtual_network studio {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.name => virtualNetwork
  }
  name                = each.value.name
  resource_group_name = each.value.resourceGroupName
  location            = each.value.regionName
  address_space       = each.value.addressSpace
  dns_servers         = each.value.dnsAddresses
  depends_on = [
    azurerm_resource_group.network_regions
  ]
}

resource azurerm_subnet studio {
  for_each = {
    for subnet in local.virtualNetworksSubnets : "${subnet.virtualNetworkName}-${subnet.name}" => subnet
  }
  name                                          = each.value.name
  resource_group_name                           = each.value.resourceGroupName
  virtual_network_name                          = each.value.virtualNetworkName
  address_prefixes                              = each.value.addressSpace
  service_endpoints                             = each.value.serviceEndpoints
  private_endpoint_network_policies_enabled     = each.value.name == "GatewaySubnet"
  private_link_service_network_policies_enabled = each.value.name == "GatewaySubnet"
  dynamic delegation {
    for_each = each.value.serviceDelegation != "" ? [1] : []
    content {
      name = "delegation"
      service_delegation {
        name = each.value.serviceDelegation
      }
    }
  }
  depends_on = [
    azurerm_virtual_network.studio
  ]
}

resource azurerm_network_security_group studio {
  for_each = {
    for subnet in local.virtualNetworksSubnetsSecurity : "${subnet.virtualNetworkName}-${subnet.name}" => subnet
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
    for subnet in local.virtualNetworksSubnetsSecurity : "${subnet.virtualNetworkName}-${subnet.name}" => subnet
  }
  subnet_id                 = "${each.value.virtualNetworkId}/subnets/${each.value.name}"
  network_security_group_id = "${each.value.resourceGroupId}/providers/Microsoft.Network/networkSecurityGroups/${each.value.virtualNetworkName}-${each.value.name}"
  depends_on = [
    azurerm_subnet.studio,
    azurerm_network_security_group.studio
  ]
}

output virtualNetwork {
  value = {
    name              = local.virtualNetwork.name
    nameSuffix        = local.virtualNetwork.nameSuffix
    regionName        = local.virtualNetwork.regionName
    resourceGroupName = local.virtualNetwork.resourceGroupName
  }
}

output virtualNetworks {
  value = [
    for virtualNetwork in local.virtualNetworks : {
      name              = virtualNetwork.name
      nameSuffix        = virtualNetwork.nameSuffix
      regionName        = virtualNetwork.regionName
      resourceGroupName = virtualNetwork.resourceGroupName
    }
  ]
}

output storageEndpointSubnets {
  value = flatten([
    for virtualNetwork in local.virtualNetworks : [
      for subnet in virtualNetwork.subnets : {
        name               = subnet.name
        resourceGroupName  = virtualNetwork.resourceGroupName
        virtualNetworkName = virtualNetwork.name
      } if contains(subnet.serviceEndpoints, "Microsoft.Storage.Global")
    ]
  ])
}
