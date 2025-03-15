#################################################################################################
# Virtual Network (https://learn.microsoft.com/azure/virtual-network/virtual-networks-overview) #
#################################################################################################

variable virtualNetworks {
  type = list(object({
    enable       = bool
    name         = string
    location     = string
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
  virtualNetworks = concat([
    for virtualNetwork in var.virtualNetworks : merge(virtualNetwork, {
      key      = "${virtualNetwork.name}-${virtualNetwork.location}"
      id       = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${var.resourceGroupName}.${virtualNetwork.location}/providers/Microsoft.Network/virtualNetworks/${virtualNetwork.name}"
      location = virtualNetwork.location
      resourceGroup = {
        name     = "${var.resourceGroupName}.${virtualNetwork.location}"
        location = virtualNetwork.location
      }
      extendedZone = null
    }) if virtualNetwork.enable
  ], module.core.resourceLocation.extendedZone.enable ? [merge(reverse(var.virtualNetworks)[0], {
    key      = "${reverse(var.virtualNetworks)[0].name}-${reverse(var.virtualNetworks)[0].location}-${module.core.resourceLocation.extendedZone.name}"
    id       = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${var.resourceGroupName}.${reverse(var.virtualNetworks)[0].location}.${module.core.resourceLocation.extendedZone.name}/providers/Microsoft.Network/virtualNetworks/${reverse(var.virtualNetworks)[0].name}"
    location = reverse(var.virtualNetworks)[0].location
    resourceGroup = {
      name     = "${var.resourceGroupName}.${reverse(var.virtualNetworks)[0].location}.${module.core.resourceLocation.extendedZone.name}"
      location = reverse(var.virtualNetworks)[0].location
    }
    extendedZone = module.core.resourceLocation.extendedZone
  })] : [])
  virtualNetworksSubnets = flatten([
    for virtualNetwork in local.virtualNetworks : [
      for subnet in virtualNetwork.subnets : merge(subnet, {
        key            = "${virtualNetwork.key}-${subnet.name}"
        location       = virtualNetwork.location
        resourceGroup  = virtualNetwork.resourceGroup
        virtualNetwork = virtualNetwork
      })
    ]
  ])
  virtualNetworksSubnetStorage = [
    for subnet in local.virtualNetworksSubnets : subnet if subnet.name == "Storage"
  ]
  virtualNetworksSubnetsSecurity = [
    for subnet in local.virtualNetworksSubnets : subnet if subnet.name != "GatewaySubnet" && subnet.name != "AzureFirewallSubnet" && subnet.name != "AzureFirewallManagementSubnet"
  ]
  virtualNetworksOutput = [
    for virtualNetwork in local.virtualNetworks : {
      name          = virtualNetwork.name
      resourceGroup = virtualNetwork.resourceGroup
      location      = virtualNetwork.location
    }
  ]
}

resource azurerm_virtual_network studio {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.key => virtualNetwork
  }
  name                = each.value.name
  resource_group_name = each.value.resourceGroup.name
  location            = each.value.location
  edge_zone           = try(each.value.extendedZone.name, null)
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
  resource_group_name                           = each.value.resourceGroup.name
  virtual_network_name                          = each.value.virtualNetwork.name
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

output virtualNetwork {
  value = {
    core      = local.virtualNetworksOutput[0]
    extended  = module.core.resourceLocation.extendedZone.enable ? reverse(local.virtualNetworksOutput)[0] : null
    locations = distinct(local.virtualNetworksOutput[*].location)
  }
}
