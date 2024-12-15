#################################################################################################
# Virtual Network (https://learn.microsoft.com/azure/virtual-network/virtual-networks-overview) #
#################################################################################################

variable virtualNetworks {
  type = list(object({
    enable       = bool
    name         = string
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
  virtualNetworksConfig = flatten([
    for virtualNetwork in var.virtualNetworks : merge(virtualNetwork, {
      regionName = virtualNetwork.regionName == "" ? module.global.resourceLocation.regionName : virtualNetwork.regionName
    }) if virtualNetwork.enable
  ])
  virtualNetwork = local.virtualNetworks[0]
  virtualNetworks = flatten([
    for virtualNetwork in local.virtualNetworksConfig : merge(virtualNetwork, {
      id                = "/subscriptions/${module.global.subscriptionId}/resourceGroups/${var.resourceGroupName}.${virtualNetwork.regionName}/providers/Microsoft.Network/virtualNetworks/${virtualNetwork.name}"
      key               = "${virtualNetwork.name}-${virtualNetwork.regionName}"
      resourceGroupId   = "/subscriptions/${module.global.subscriptionId}/resourceGroups/${var.resourceGroupName}.${virtualNetwork.regionName}"
      resourceGroupName = "${var.resourceGroupName}.${virtualNetwork.regionName}"
      extendedZoneName  = ""
    })
  ])
  virtualNetworksExtended = distinct(concat(local.virtualNetworks, !module.global.resourceLocation.extendedZone.enable ? [local.virtualNetwork] : [
    merge(local.virtualNetwork, {
      id                = "/subscriptions/${module.global.subscriptionId}/resourceGroups/${var.resourceGroupName}.${module.global.resourceLocation.extendedZone.regionName}.${module.global.resourceLocation.extendedZone.name}/providers/Microsoft.Network/virtualNetworks/${local.virtualNetwork.name}"
      key               = "${local.virtualNetwork.name}-${module.global.resourceLocation.extendedZone.regionName}-${module.global.resourceLocation.extendedZone.name}"
      resourceGroupId   = "/subscriptions/${module.global.subscriptionId}/resourceGroups/${var.resourceGroupName}.${module.global.resourceLocation.extendedZone.regionName}.${module.global.resourceLocation.extendedZone.name}"
      resourceGroupName = "${var.resourceGroupName}.${module.global.resourceLocation.extendedZone.regionName}.${module.global.resourceLocation.extendedZone.name}"
      regionName        = module.global.resourceLocation.extendedZone.regionName
      extendedZoneName  = module.global.resourceLocation.extendedZone.name
    })
  ]))
  virtualNetworksSubnets = flatten([
    for virtualNetwork in local.virtualNetworksExtended : [
      for subnet in virtualNetwork.subnets : merge(subnet, {
        key                            = "${virtualNetwork.key}-${subnet.name}"
        regionName                     = virtualNetwork.regionName
        resourceGroupId                = virtualNetwork.resourceGroupId
        resourceGroupName              = virtualNetwork.resourceGroupName
        virtualNetworkKey              = virtualNetwork.key
        virtualNetworkId               = virtualNetwork.id
        virtualNetworkName             = virtualNetwork.name
        virtualNetworkExtendedZoneName = virtualNetwork.extendedZoneName
      }) if virtualNetwork.extendedZoneName == "" || (virtualNetwork.extendedZoneName != "" && subnet.serviceDelegation == null)
    ]
  ])
  virtualNetworksSubnetStorage = [
    for subnet in local.virtualNetworksSubnets : subnet if subnet.name == "Storage" && subnet.virtualNetworkExtendedZoneName == ""
  ]
  virtualNetworksSubnetsSecurity = [
    for subnet in local.virtualNetworksSubnets : subnet if subnet.name != "GatewaySubnet" && subnet.name != "AzureFirewallSubnet" && subnet.name != "AzureFirewallManagementSubnet"
  ]
}

resource azurerm_virtual_network studio {
  for_each = {
    for virtualNetwork in local.virtualNetworksExtended : virtualNetwork.key => virtualNetwork
  }
  name                = each.value.name
  resource_group_name = each.value.resourceGroupName
  location            = each.value.regionName
  edge_zone           = each.value.extendedZoneName != "" ? each.value.extendedZoneName : null
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
  service_endpoints                             = length(each.value.serviceEndpoints) > 0 ? each.value.serviceEndpoints : null
  private_endpoint_network_policies             = each.value.name == "GatewaySubnet" ? "Enabled" : "Disabled"
  private_link_service_network_policies_enabled = each.value.name == "GatewaySubnet"
  default_outbound_access_enabled               = false
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

output virtualNetworks {
  value = [
    for virtualNetwork in local.virtualNetworksExtended : {
      key               = virtualNetwork.key
      id                = virtualNetwork.id
      name              = virtualNetwork.name
      resourceGroupName = virtualNetwork.resourceGroupName
      regionName        = virtualNetwork.regionName
      extendedZoneName  = virtualNetwork.extendedZoneName
    }
  ]
}
