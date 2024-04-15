###############################################################################################################
# Virtual Network Gateway (VPN) (https://learn.microsoft.com/azure/vpn-gateway/vpn-gateway-about-vpngateways) #
###############################################################################################################

variable vpnGateway {
  type = object({
    enable             = bool
    sku                = string
    type               = string
    generation         = string
    sharedKey          = string
    enableBgp          = bool
    enablePerRegion    = bool
    enableActiveActive = bool
    pointToSiteClient = object({
      addressSpace = list(string)
      rootCertificate = object({
        name = string
        data = string
      })
    })
  })
}

variable vpnGatewayLocal {
  type = object({
    fqdn         = string
    address      = string
    addressSpace = list(string)
    bgp = object({
      enable         = bool
      asn            = number
      peerWeight     = number
      peeringAddress = string
    })
  })
}

locals {
  vpnGatewayNetworks = var.vpnGateway.enable ? var.vpnGateway.enablePerRegion ? local.virtualNetworks : [local.virtualNetworks[0]] : []
}

resource azurerm_virtual_network_gateway vpn {
  for_each = {
    for virtualNetwork in local.vpnGatewayNetworks : virtualNetwork.name => virtualNetwork
  }
  name                = "Gateway-VPN"
  resource_group_name = each.value.resourceGroupName
  location            = each.value.regionName
  type                = "Vpn"
  sku                 = var.vpnGateway.sku
  vpn_type            = var.vpnGateway.type
  generation          = var.vpnGateway.generation
  enable_bgp          = var.vpnGateway.enableBgp
  active_active       = var.vpnGateway.enableActiveActive
  ip_configuration {
    name                 = "ipConfig1"
    subnet_id            = "${each.value.id}/subnets/GatewaySubnet"
    public_ip_address_id = "/subscriptions/${data.azurerm_client_config.studio.subscription_id}/resourceGroups/${each.value.vpnGateway.ipAddress1.resourceGroupName}/providers/Microsoft.Network/publicIPAddresses/${each.value.vpnGateway.ipAddress1.name}"
  }
  dynamic ip_configuration {
    for_each = var.vpnGateway.enableActiveActive ? [1] : []
    content {
      name                 = "ipConfig2"
      subnet_id            = "${each.value.id}/subnets/GatewaySubnet"
      public_ip_address_id = "/subscriptions/${data.azurerm_client_config.studio.subscription_id}/resourceGroups/${each.value.vpnGateway.ipAddress2.resourceGroupName}/providers/Microsoft.Network/publicIPAddresses/${each.value.vpnGateway.ipAddress2.name}"
    }
  }
  dynamic vpn_client_configuration {
    for_each = length(var.vpnGateway.pointToSiteClient.addressSpace) > 0 ? [1] : []
    content {
      address_space = var.vpnGateway.pointToSiteClient.addressSpace
      root_certificate {
        name             = var.vpnGateway.pointToSiteClient.rootCertificate.name
        public_cert_data = var.vpnGateway.pointToSiteClient.rootCertificate.data
      }
    }
  }
  depends_on = [
    azurerm_subnet_network_security_group_association.studio
  ]
}

##########################################################################################################################
# Local Network Gateway (VPN) (https://learn.microsoft.com/azure/vpn-gateway/vpn-gateway-about-vpn-gateway-settings#lng) #
##########################################################################################################################

resource azurerm_local_network_gateway vpn {
  for_each = {
    for virtualNetwork in local.vpnGatewayNetworks : virtualNetwork.name => virtualNetwork if var.vpnGatewayLocal.fqdn != "" || var.vpnGatewayLocal.address != ""
  }
  name                = each.value.name
  resource_group_name = each.value.resourceGroupName
  location            = each.value.regionName
  gateway_fqdn        = var.vpnGatewayLocal.address == "" ? var.vpnGatewayLocal.fqdn : null
  gateway_address     = var.vpnGatewayLocal.fqdn == "" ? var.vpnGatewayLocal.address : null
  address_space       = var.vpnGatewayLocal.addressSpace
  dynamic bgp_settings {
    for_each = var.vpnGatewayLocal.bgp.enable ? [1] : []
    content {
      asn                 = var.vpnGatewayLocal.bgp.asn
      peer_weight         = var.vpnGatewayLocal.bgp.peerWeight
      bgp_peering_address = var.vpnGatewayLocal.bgp.peeringAddress
    }
  }
  depends_on = [
    azurerm_resource_group.network_regions
  ]
}

resource azurerm_virtual_network_gateway_connection site_to_site {
  for_each = {
    for virtualNetwork in local.vpnGatewayNetworks : virtualNetwork.name => virtualNetwork if var.vpnGatewayLocal.fqdn != "" || var.vpnGatewayLocal.address != ""
  }
  name                       = each.value.name
  resource_group_name        = each.value.resourceGroupName
  location                   = each.value.regionName
  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vpn[each.value.name].id
  local_network_gateway_id   = azurerm_local_network_gateway.vpn[each.value.name].id
  shared_key                 = var.vpnGateway.sharedKey != "" || !module.global.keyVault.enable ? var.vpnGateway.sharedKey : data.azurerm_key_vault_secret.gateway_connection[0].value
  enable_bgp                 = var.vpnGatewayLocal.bgp.enable
}
