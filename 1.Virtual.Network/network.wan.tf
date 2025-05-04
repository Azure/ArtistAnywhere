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
        scaleUnit = object({
          minCount = number
        })
        routes = list(object({
          enable       = bool
          nextAddress  = string
          addressSpace = list(string)
        }))
      })
      vpnGateway = object({
        enable     = bool
        name       = string
        scaleUnits = number
        siteToSite = bool
        client = object({
          addressSpace = list(string)
        })
      })
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
  virtual_router_auto_scale_min_capacity = each.value.router.scaleUnit.minCount
  dynamic route {
    for_each = [
      for route in each.value.router.routes : route if route.enable
    ]
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

####################################################################################################
# Point-to-Site VPN Gateway (https://learn.microsoft.com/azure/virtual-wan/point-to-site-concepts) #
####################################################################################################

resource azurerm_vpn_server_configuration studio {
  for_each = {
    for hub in var.virtualWAN.hubs : hub.name => hub if var.virtualWAN.enable && hub.enable && hub.vpnGateway.enable && !hub.vpnGateway.siteToSite
  }
  name                     = each.value.vpnGateway.name
  resource_group_name      = azurerm_virtual_hub.studio[each.value.name].resource_group_name
  location                 = azurerm_virtual_hub.studio[each.value.name].location
  vpn_protocols            = ["OpenVPN"]
  vpn_authentication_types = ["AAD"]
  azure_active_directory_authentication {
    tenant   = "https://login.microsoftonline.com/${data.azurerm_subscription.current.tenant_id}"
    issuer   = "https://sts.windows.net/${data.azurerm_subscription.current.tenant_id}/"
    audience = "c632b3df-fb67-4d84-bdcf-b95ad541b5c8" # Azure VPN Client
  }
}

resource azurerm_point_to_site_vpn_gateway studio {
  for_each = {
    for hub in var.virtualWAN.hubs : hub.name => hub if var.virtualWAN.enable && hub.enable && hub.vpnGateway.enable && !hub.vpnGateway.siteToSite
  }
  name                        = each.value.vpnGateway.name
  resource_group_name         = azurerm_virtual_hub.studio[each.value.name].resource_group_name
  location                    = azurerm_virtual_hub.studio[each.value.name].location
  virtual_hub_id              = azurerm_virtual_hub.studio[each.value.name].id
  vpn_server_configuration_id = azurerm_vpn_server_configuration.studio[each.value.name].id
  scale_unit                  = each.value.vpnGateway.scaleUnits
  connection_configuration {
    name = each.value.vpnGateway.name
    vpn_client_address_pool {
      address_prefixes = each.value.vpnGateway.client.addressSpace
    }
  }
}

#################################################################################################################
# Site-to-Site VPN Gateway (https://learn.microsoft.com/azure/virtual-wan/connect-virtual-network-gateway-vwan) #
#################################################################################################################

resource azurerm_vpn_gateway studio {
  for_each = {
    for hub in var.virtualWAN.hubs : hub.name => hub if var.virtualWAN.enable && hub.enable && hub.vpnGateway.enable && hub.vpnGateway.siteToSite
  }
  name                = each.value.vpnGateway.name
  resource_group_name = azurerm_virtual_hub.studio[each.value.name].resource_group_name
  location            = azurerm_virtual_hub.studio[each.value.name].location
  virtual_hub_id      = azurerm_virtual_hub.studio[each.value.name].id
  scale_unit          = each.value.vpnGateway.scaleUnits
}
