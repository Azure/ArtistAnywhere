#############################################################################################
# VPN Gateway (https://learn.microsoft.com/azure/vpn-gateway/vpn-gateway-about-vpngateways) #
#############################################################################################

variable vpnGateway {
  type = object({
    enable  = bool
    name    = string
    sites = list(object({
      enable     = bool
      name       = string
      hubName    = string
      scaleUnits = number
      siteToSite = object({
        enable       = bool
        addressSpace = list(string)
        link = object({
          fqdn    = string
          address = string
        })
        bgp = object({
          enable = bool
          asn    = number
          peering = object({
            address = string
          })
        })
      })
      pointToSite = object({
        enable = bool
        client = object({
          addressSpace = list(string)
        })
      })
    }))
  })
}

#################################################################################################################
# Site-to-Site VPN Gateway (https://learn.microsoft.com/azure/virtual-wan/connect-virtual-network-gateway-vwan) #
#################################################################################################################

resource azurerm_vpn_gateway main {
  for_each = {
    for site in var.vpnGateway.sites : site.name => site if var.vpnGateway.enable && site.siteToSite.enable && site.enable
  }
  name                = "${var.vpnGateway.name}-${each.value.name}"
  resource_group_name = azurerm_virtual_hub.main[each.value.hubName].resource_group_name
  location            = azurerm_virtual_hub.main[each.value.hubName].location
  virtual_hub_id      = azurerm_virtual_hub.main[each.value.hubName].id
  scale_unit          = each.value.scaleUnits
}

resource azurerm_vpn_site main {
  for_each = {
    for site in var.vpnGateway.sites : site.name => site if var.virtualWAN.enable && var.vpnGateway.enable && site.siteToSite.enable && site.enable
  }
  name                = "${var.vpnGateway.name}-${each.value.name}"
  resource_group_name = azurerm_virtual_hub.main[each.value.hubName].resource_group_name
  location            = azurerm_virtual_hub.main[each.value.hubName].location
  virtual_wan_id      = azurerm_virtual_wan.main[0].id
  address_cidrs       = each.value.siteToSite.addressSpace
  link {
    name       = "default"
    fqdn       = each.value.fqdn != "" ? each.value.fqdn : null
    ip_address = each.value.address != "" ? each.value.address : null
    dynamic bgp {
      for_each = each.value.siteToSite.bgp.enable ? [1] : []
      content {
        asn             = each.value.siteToSite.bgp.asn
        peering_address = each.value.siteToSite.bgp.peering.address
      }
    }
  }
}

####################################################################################################
# Point-to-Site VPN Gateway (https://learn.microsoft.com/azure/virtual-wan/point-to-site-concepts) #
####################################################################################################

resource azurerm_vpn_server_configuration main {
  for_each = {
    for site in var.vpnGateway.sites : site.name => site if var.vpnGateway.enable && site.pointToSite.enable && site.enable
  }
  name                     = "${var.vpnGateway.name}-${each.value.name}"
  resource_group_name      = azurerm_virtual_hub.main[each.value.hubName].resource_group_name
  location                 = azurerm_virtual_hub.main[each.value.hubName].location
  vpn_protocols            = ["OpenVPN"]
  vpn_authentication_types = ["AAD"]
  azure_active_directory_authentication {
    tenant   = "https://login.microsoftonline.com/${data.azurerm_subscription.current.tenant_id}"
    issuer   = "https://sts.windows.net/${data.azurerm_subscription.current.tenant_id}/"
    audience = "c632b3df-fb67-4d84-bdcf-b95ad541b5c8" # Azure VPN Client
  }
}

resource azurerm_point_to_site_vpn_gateway main {
  for_each = {
    for site in var.vpnGateway.sites : site.name => site if var.vpnGateway.enable && site.pointToSite.enable && site.enable
  }
  name                        = "${var.vpnGateway.name}-${each.value.name}"
  resource_group_name         = azurerm_virtual_hub.main[each.value.hubName].resource_group_name
  location                    = azurerm_virtual_hub.main[each.value.hubName].location
  virtual_hub_id              = azurerm_virtual_hub.main[each.value.hubName].id
  vpn_server_configuration_id = azurerm_vpn_server_configuration.main[each.value.name].id
  scale_unit                  = each.value.scaleUnits
  connection_configuration {
    name = var.vpnGateway.name
    vpn_client_address_pool {
      address_prefixes = each.value.pointToSite.client.addressSpace
    }
  }
}
