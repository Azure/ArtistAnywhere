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
      name             = string
      addressSpace     = list(string)
      serviceEndpoints = list(string)
      serviceDelegation = object({
        service = string
        actions = list(string)
      })
    }))
  }))
}

locals {
  virtualNetwork  = local.virtualNetworks[0]
  virtualNetworks = distinct(concat(module.global.resourceLocation.edgeZone == "" ? [local.virtualNetworksRegional[0]] : [merge(local.virtualNetworksRegional[0], {
    id                = "/subscriptions/${data.azurerm_client_config.studio.subscription_id}/resourceGroups/${local.virtualNetworksRegional[0].resourceGroupName}.Edge/providers/Microsoft.Network/virtualNetworks/${local.virtualNetworksRegional[0].name}-Edge"
    name              = "${local.virtualNetworksRegional[0].name}-Edge"
    resourceGroupName = "${local.virtualNetworksRegional[0].resourceGroupName}.Edge"
    edgeZone          = module.global.resourceLocation.edgeZone
  })], local.virtualNetworksRegional))
  virtualNetworksNames = [
    for virtualNetwork in var.virtualNetworks : merge(virtualNetwork, {
      regionName        = virtualNetwork.regionName != "" ? virtualNetwork.regionName : module.global.resourceLocation.region
      edgeZone          = ""
      name              = virtualNetwork.nameSuffix != "" ? "${virtualNetwork.name}-${virtualNetwork.nameSuffix}" : virtualNetwork.name
      resourceGroupName = virtualNetwork.nameSuffix != "" ? "${var.resourceGroupName}.${virtualNetwork.nameSuffix}" : var.resourceGroupName
    }) if virtualNetwork.enable
  ]
  virtualNetworksRegional = [
    for virtualNetwork in local.virtualNetworksNames : merge(virtualNetwork, {
      id              = "/subscriptions/${data.azurerm_client_config.studio.subscription_id}/resourceGroups/${virtualNetwork.resourceGroupName}/providers/Microsoft.Network/virtualNetworks/${virtualNetwork.name}"
      resourceGroupId = "/subscriptions/${data.azurerm_client_config.studio.subscription_id}/resourceGroups/${virtualNetwork.resourceGroupName}"
    })
  ]
  virtualNetworksSubnets = flatten([
    for virtualNetwork in local.virtualNetworks : [
      for subnet in virtualNetwork.subnets : merge(subnet, {
        key                    = "${virtualNetwork.name}-${subnet.name}"
        regionName             = virtualNetwork.regionName
        resourceGroupId        = virtualNetwork.resourceGroupId
        resourceGroupName      = virtualNetwork.resourceGroupName
        virtualNetworkId       = virtualNetwork.id
        virtualNetworkName     = virtualNetwork.name
        virtualNetworkEdgeZone = virtualNetwork.edgeZone
      }) if virtualNetwork.edgeZone == "" || (virtualNetwork.edgeZone != "" && subnet.serviceDelegation == null)
    ]
  ])
  virtualNetworksSubnetStorage = [
    for subnet in local.virtualNetworksSubnets : subnet if subnet.name == "Storage" && subnet.virtualNetworkEdgeZone == ""
  ]
  virtualNetworksSubnetsSecurity = [
    for subnet in local.virtualNetworksSubnets : subnet if subnet.name != "GatewaySubnet" && subnet.name != "AzureBastionSubnet" && subnet.virtualNetworkEdgeZone == ""
  ]
}

resource azurerm_virtual_network studio {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.name => virtualNetwork
  }
  name                = each.value.name
  resource_group_name = each.value.resourceGroupName
  location            = each.value.regionName
  edge_zone           = each.value.edgeZone != "" ? each.value.edgeZone : null
  address_space       = each.value.addressSpace
  dns_servers         = each.value.dnsAddresses
  depends_on = [
    azurerm_resource_group.network_regions
  ]
}

resource azurerm_subnet studio {
  for_each = {
    for subnet in local.virtualNetworksSubnets : subnet.key => subnet
  }
  name                                          = each.value.name
  resource_group_name                           = each.value.resourceGroupName
  virtual_network_name                          = each.value.virtualNetworkName
  address_prefixes                              = each.value.addressSpace
  service_endpoints                             = each.value.serviceEndpoints
  private_endpoint_network_policies_enabled     = each.value.name == "GatewaySubnet"
  private_link_service_network_policies_enabled = each.value.name == "GatewaySubnet"
  dynamic delegation {
    for_each = each.value.serviceDelegation != null ? [1] : []
    content {
      name = each.value.name
      service_delegation {
        name    = each.value.serviceDelegation.service
        actions = each.value.serviceDelegation.actions
      }
    }
  }
  depends_on = [
    azurerm_virtual_network.studio
  ]
}

resource azurerm_network_security_group studio {
  for_each = {
    for subnet in local.virtualNetworksSubnetsSecurity : subnet.key => subnet
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
    for subnet in local.virtualNetworksSubnetsSecurity : subnet.key => subnet
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
    edgeZone          = local.virtualNetwork.edgeZone
    resourceGroupName = local.virtualNetwork.resourceGroupName
  }
}

output virtualNetworkRegional {
  value = {
    name              = local.virtualNetworksRegional[0].name
    nameSuffix        = local.virtualNetworksRegional[0].nameSuffix
    regionName        = local.virtualNetworksRegional[0].regionName
    edgeZone          = local.virtualNetworksRegional[0].edgeZone
    resourceGroupName = local.virtualNetworksRegional[0].resourceGroupName
  }
}

output virtualNetworks {
  value = [
    for virtualNetwork in local.virtualNetworks : {
      name              = virtualNetwork.name
      nameSuffix        = virtualNetwork.nameSuffix
      regionName        = virtualNetwork.regionName
      edgeZone          = virtualNetwork.edgeZone
      resourceGroupName = virtualNetwork.resourceGroupName
    }
  ]
}

output virtualNetworksRegional {
  value = [
    for virtualNetwork in local.virtualNetworksRegional : {
      name              = virtualNetwork.name
      nameSuffix        = virtualNetwork.nameSuffix
      regionName        = virtualNetwork.regionName
      edgeZone          = virtualNetwork.edgeZone
      resourceGroupName = virtualNetwork.resourceGroupName
    }
  ]
}

output storageEndpointSubnets {
  value = flatten([
    for virtualNetwork in local.virtualNetworks : [
      for subnet in virtualNetwork.subnets : {
        name                   = subnet.name
        virtualNetworkName     = virtualNetwork.name
        virtualNetworkEdgeZone = virtualNetwork.edgeZone
        regionName             = virtualNetwork.regionName
        resourceGroupName      = virtualNetwork.resourceGroupName
      } if contains(subnet.serviceEndpoints, "Microsoft.Storage.Global")
    ]
  ])
}
