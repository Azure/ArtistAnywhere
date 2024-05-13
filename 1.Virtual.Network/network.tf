#################################################################################################
# Virtual Network (https://learn.microsoft.com/azure/virtual-network/virtual-networks-overview) #
#################################################################################################

variable virtualNetworks {
  type = list(object({
    enable       = bool
    name         = string
    nameSuffix   = string
    regionNames  = list(string)
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
  virtualNetworks = [
    for virtualNetwork in local.virtualNetworksNames : merge(virtualNetwork, {
      id              = "/subscriptions/${data.azurerm_client_config.studio.subscription_id}/resourceGroups/${virtualNetwork.resourceGroupName}/providers/Microsoft.Network/virtualNetworks/${virtualNetwork.name}"
      resourceGroupId = "/subscriptions/${data.azurerm_client_config.studio.subscription_id}/resourceGroups/${virtualNetwork.resourceGroupName}"
    })
  ]
  virtualNetworksNames = flatten([
    for virtualNetwork in var.virtualNetworks : [
      for regionName in virtualNetwork.regionNames : merge(virtualNetwork, {
        key               = "${virtualNetwork.name}-${virtualNetwork.nameSuffix}-${regionName}"
        name              = "${virtualNetwork.name}-${virtualNetwork.nameSuffix}"
        resourceGroupName = "${var.resourceGroupName}.${regionName}"
        regionName        = regionName
        edgeZone          = ""
      }) if virtualNetwork.enable
    ]
  ])
  virtualNetworksExtended = distinct(concat(local.virtualNetworks, !module.global.resourceLocation.edgeZone.enable ? concat([local.virtualNetworks[0]], [local.virtualNetworks[0]]) : [
    merge(local.virtualNetworks[0], {
      id                = "/subscriptions/${data.azurerm_client_config.studio.subscription_id}/resourceGroups/${var.resourceGroupName}.${module.global.resourceLocation.edgeZone.regionName}/providers/Microsoft.Network/virtualNetworks/${local.virtualNetworks[0].name}"
      key               = "${local.virtualNetworks[0].name}-${module.global.resourceLocation.edgeZone.regionName}"
      resourceGroupId   = "/subscriptions/${data.azurerm_client_config.studio.subscription_id}/resourceGroups/${var.resourceGroupName}.${module.global.resourceLocation.edgeZone.regionName}"
      resourceGroupName = "${var.resourceGroupName}.${module.global.resourceLocation.edgeZone.regionName}"
      regionName        = module.global.resourceLocation.edgeZone.regionName
    }),
    merge(local.virtualNetworks[0], {
      id                = "/subscriptions/${data.azurerm_client_config.studio.subscription_id}/resourceGroups/${var.resourceGroupName}.${module.global.resourceLocation.edgeZone.regionName}.${module.global.resourceLocation.edgeZone.name}/providers/Microsoft.Network/virtualNetworks/${local.virtualNetworks[0].name}"
      key               = "${local.virtualNetworks[0].name}-${module.global.resourceLocation.edgeZone.regionName}-${module.global.resourceLocation.edgeZone.name}"
      resourceGroupId   = "/subscriptions/${data.azurerm_client_config.studio.subscription_id}/resourceGroups/${var.resourceGroupName}.${module.global.resourceLocation.edgeZone.regionName}.${module.global.resourceLocation.edgeZone.name}"
      resourceGroupName = "${var.resourceGroupName}.${module.global.resourceLocation.edgeZone.regionName}.${module.global.resourceLocation.edgeZone.name}"
      regionName        = module.global.resourceLocation.edgeZone.regionName
      edgeZone          = module.global.resourceLocation.edgeZone.name
    })
  ]))
  virtualNetworksSubnets = flatten([
    for virtualNetwork in local.virtualNetworksExtended : [
      for subnet in virtualNetwork.subnets : merge(subnet, {
        key                    = "${virtualNetwork.key}-${subnet.name}"
        regionName             = virtualNetwork.regionName
        resourceGroupId        = virtualNetwork.resourceGroupId
        resourceGroupName      = virtualNetwork.resourceGroupName
        virtualNetworkKey      = virtualNetwork.key
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
    for subnet in local.virtualNetworksSubnets : subnet if subnet.name != "GatewaySubnet"
  ]
}

resource azurerm_virtual_network studio {
  for_each = {
    for virtualNetwork in local.virtualNetworksExtended : virtualNetwork.key => virtualNetwork
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

output virtualNetworks {
  value = [
    for virtualNetwork in local.virtualNetworksExtended : {
      key               = virtualNetwork.key
      id                = virtualNetwork.id
      name              = virtualNetwork.name
      resourceGroupName = virtualNetwork.resourceGroupName
      regionName        = virtualNetwork.regionName
      edgeZone          = virtualNetwork.edgeZone
    }
  ]
}

output virtualNetworksSubnetStorage {
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
