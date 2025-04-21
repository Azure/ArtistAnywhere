#################################################################################
# Virtual WAN (https://learn.microsoft.com/azure/virtual-wan/virtual-wan-about) #
#################################################################################

variable virtualWAN {
  type = object({
    enable = bool
    name   = string
    type   = string
    hubs = list(object({
      enable       = bool
      name         = string
      type         = string
      location     = string
      addressSpace = string
      router = object({
        preferenceMode = string
        instanceCount = object({
          minimum = number
        })
      })
      routes = list(object({
        enable       = bool
        nextAddress  = string
        addressSpace = list(string)
      }))
    }))
  })
}

resource azurerm_virtual_wan studio {
  count               = var.virtualWAN.enable ? 1 : 0
  name                = var.virtualWAN.name
  resource_group_name = azurerm_resource_group.network.name
  location            = azurerm_resource_group.network.location
  type                = var.virtualWAN.type
}

resource azurerm_virtual_hub studio {
  for_each = {
    for hub in var.virtualWAN.hubs : hub.name => hub if var.virtualWAN.enable && hub.enable
  }
  name                                   = each.value.name
  resource_group_name                    = azurerm_virtual_wan.studio[0].resource_group_name
  location                               = each.value.location
  virtual_wan_id                         = azurerm_virtual_wan.studio[0].id
  sku                                    = each.value.type
  address_prefix                         = each.value.addressSpace
  hub_routing_preference                 = each.value.router.preferenceMode
  virtual_router_auto_scale_min_capacity = each.value.router.instanceCount.minimum
  dynamic route {
    for_each = {
      for route in each.value.routes : route.addressSpace => route if route.enable
    }
    content {
      next_hop_ip_address = route.nextAddress
      address_prefixes    = route.addressSpace
    }
  }
}

resource azurerm_virtual_hub_connection studio {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.key => virtualNetwork if var.virtualWAN.enable
  }
  name                      = each.value.key
  remote_virtual_network_id = each.value.id
  virtual_hub_id            = azurerm_virtual_hub.studio[each.value.hubName].id
}
