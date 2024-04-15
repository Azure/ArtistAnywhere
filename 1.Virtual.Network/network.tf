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
    vpnGateway = object({
      ipAddress1 = object({
        name              = string
        resourceGroupName = string
      })
      ipAddress2 = object({
        name              = string
        resourceGroupName = string
      })
    })
  }))
}

locals {
  virtualNetwork = module.global.resourceLocation.edgeZone != "" ? local.virtualNetworksExtended[0] : local.virtualNetworks[0]
  virtualNetworks = [
    for virtualNetwork in local.virtualNetworksNames : merge(virtualNetwork, {
      id              = "/subscriptions/${data.azurerm_client_config.studio.subscription_id}/resourceGroups/${virtualNetwork.resourceGroupName}/providers/Microsoft.Network/virtualNetworks/${virtualNetwork.name}"
      resourceGroupId = "/subscriptions/${data.azurerm_client_config.studio.subscription_id}/resourceGroups/${virtualNetwork.resourceGroupName}"
    })
  ]
  virtualNetworksNames = [
    for virtualNetwork in var.virtualNetworks : merge(virtualNetwork, {
      regionName        = virtualNetwork.regionName != "" ? virtualNetwork.regionName : module.global.resourceLocation.region
      edgeZone          = ""
      name              = virtualNetwork.nameSuffix != "" ? "${virtualNetwork.name}-${virtualNetwork.nameSuffix}" : virtualNetwork.name
      resourceGroupName = virtualNetwork.nameSuffix != "" ? "${var.resourceGroupName}.${virtualNetwork.nameSuffix}" : var.resourceGroupName
    }) if virtualNetwork.enable
  ]
  virtualNetworksExtended = distinct(concat([module.global.resourceLocation.edgeZone == "" ? local.virtualNetworks[0] : merge(local.virtualNetworks[0], {
    id                = "/subscriptions/${data.azurerm_client_config.studio.subscription_id}/resourceGroups/${local.virtualNetworks[0].resourceGroupName}.Edge/providers/Microsoft.Network/virtualNetworks/${local.virtualNetworks[0].name}-Edge"
    name              = "${local.virtualNetworks[0].name}-Edge"
    resourceGroupName = "${local.virtualNetworks[0].resourceGroupName}.Edge"
    edgeZone          = module.global.resourceLocation.edgeZone
  })], local.virtualNetworks))
  virtualNetworksSubnets = flatten([
    for virtualNetwork in local.virtualNetworksExtended : [
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
  virtualNetworksSubnetCompute = [
    for subnet in local.virtualNetworksSubnets : subnet if subnet.name == "Farm" && subnet.virtualNetworkEdgeZone == ""
  ]
  virtualNetworksSubnetsSecurity = [
    for subnet in local.virtualNetworksSubnets : subnet if subnet.name != "GatewaySubnet" && subnet.name != "AzureBastionSubnet" && subnet.virtualNetworkEdgeZone == ""
  ]
}

resource azurerm_virtual_network studio {
  for_each = {
    for virtualNetwork in local.virtualNetworksExtended : virtualNetwork.name => virtualNetwork
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

output virtualNetwork {
  value = {
    id                = local.virtualNetwork.id
    name              = local.virtualNetwork.name
    nameSuffix        = local.virtualNetwork.nameSuffix
    regionName        = local.virtualNetwork.regionName
    edgeZone          = local.virtualNetwork.edgeZone
    resourceGroupName = local.virtualNetwork.resourceGroupName
  }
}

output virtualNetworks {
  value = [
    for virtualNetwork in local.virtualNetworks : {
      id                = virtualNetwork.id
      name              = virtualNetwork.name
      nameSuffix        = virtualNetwork.nameSuffix
      regionName        = virtualNetwork.regionName
      edgeZone          = virtualNetwork.edgeZone
      resourceGroupName = virtualNetwork.resourceGroupName
    }
  ]
}

output virtualNetworksSubnetStorage {
  value = flatten([
    for virtualNetwork in local.virtualNetworks : [
      for subnet in virtualNetwork.subnets : {
        name                   = subnet.name
        virtualNetworkId       = virtualNetwork.id
        virtualNetworkName     = virtualNetwork.name
        virtualNetworkEdgeZone = virtualNetwork.edgeZone
        regionName             = virtualNetwork.regionName
        resourceGroupName      = virtualNetwork.resourceGroupName
      } if contains(subnet.serviceEndpoints, "Microsoft.Storage.Global")
    ]
  ])
}

output virtualNetworksSubnetCompute {
  value = local.virtualNetworksSubnetCompute
}
