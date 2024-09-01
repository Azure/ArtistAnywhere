#################################################################################################
# Virtual Network (https://learn.microsoft.com/azure/virtual-network/virtual-networks-overview) #
#################################################################################################

variable virtualNetworks {
  type = list(object({
    enable       = bool
    name         = string
    regionNames  = list(string)
    addressSpace = list(string)
    dnsAddresses = list(string)
    subnets = list(object({
      name         = string
      addressSpace = list(string)
      serviceDelegation = object({
        service = string
        actions = list(string)
      })
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
  virtualNetworksConfig = [
    for virtualNetwork in var.virtualNetworks : merge(virtualNetwork, {
      regionNames = length(virtualNetwork.regionNames) == 0 ? [module.global.resourceLocation.regionName] : virtualNetwork.regionNames
    })
  ]
  virtualNetworksNames = flatten([
    for virtualNetwork in local.virtualNetworksConfig : [
      for regionName in virtualNetwork.regionNames : merge(virtualNetwork, {
        key               = "${virtualNetwork.name}-${regionName}"
        resourceGroupName = "${var.resourceGroupName}.${regionName}"
        regionName        = regionName
        extendedZone      = ""
      }) if virtualNetwork.enable
    ]
  ])
  virtualNetworksExtended = distinct(concat(local.virtualNetworks, !module.global.resourceLocation.extendedZone.enable ? concat([local.virtualNetwork], [local.virtualNetwork]) : [
    merge(local.virtualNetwork, {
      id                = "/subscriptions/${data.azurerm_client_config.studio.subscription_id}/resourceGroups/${var.resourceGroupName}.${module.global.resourceLocation.extendedZone.regionName}/providers/Microsoft.Network/virtualNetworks/${local.virtualNetwork.name}"
      key               = "${local.virtualNetwork.name}-${module.global.resourceLocation.extendedZone.regionName}"
      resourceGroupId   = "/subscriptions/${data.azurerm_client_config.studio.subscription_id}/resourceGroups/${var.resourceGroupName}.${module.global.resourceLocation.extendedZone.regionName}"
      resourceGroupName = "${var.resourceGroupName}.${module.global.resourceLocation.extendedZone.regionName}"
      regionName        = module.global.resourceLocation.extendedZone.regionName
    }),
    merge(local.virtualNetwork, {
      id                = "/subscriptions/${data.azurerm_client_config.studio.subscription_id}/resourceGroups/${var.resourceGroupName}.${module.global.resourceLocation.extendedZone.regionName}.${module.global.resourceLocation.extendedZone.name}/providers/Microsoft.Network/virtualNetworks/${local.virtualNetwork.name}"
      key               = "${local.virtualNetwork.name}-${module.global.resourceLocation.extendedZone.regionName}-${module.global.resourceLocation.extendedZone.name}"
      resourceGroupId   = "/subscriptions/${data.azurerm_client_config.studio.subscription_id}/resourceGroups/${var.resourceGroupName}.${module.global.resourceLocation.extendedZone.regionName}.${module.global.resourceLocation.extendedZone.name}"
      resourceGroupName = "${var.resourceGroupName}.${module.global.resourceLocation.extendedZone.regionName}.${module.global.resourceLocation.extendedZone.name}"
      regionName        = module.global.resourceLocation.extendedZone.regionName
      extendedZone      = module.global.resourceLocation.extendedZone.name
    })
  ]))
  virtualNetworksSubnets = flatten([
    for virtualNetwork in local.virtualNetworksExtended : [
      for subnet in virtualNetwork.subnets : merge(subnet, {
        key                        = "${virtualNetwork.key}-${subnet.name}"
        regionName                 = virtualNetwork.regionName
        resourceGroupId            = virtualNetwork.resourceGroupId
        resourceGroupName          = virtualNetwork.resourceGroupName
        virtualNetworkKey          = virtualNetwork.key
        virtualNetworkId           = virtualNetwork.id
        virtualNetworkName         = virtualNetwork.name
        virtualNetworkExtendedZone = virtualNetwork.extendedZone
      }) if virtualNetwork.extendedZone == "" || (virtualNetwork.extendedZone != "" && subnet.serviceDelegation == null)
    ]
  ])
  virtualNetworksSubnetStorage = [
    for subnet in local.virtualNetworksSubnets : subnet if subnet.name == "Storage" && subnet.virtualNetworkExtendedZone == ""
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
  edge_zone           = each.value.extendedZone != "" ? each.value.extendedZone : null
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
  private_endpoint_network_policies             = each.value.name == "GatewaySubnet" ? "Enabled" : "Disabled"
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
      extendedZone      = virtualNetwork.extendedZone
    }
  ]
}
