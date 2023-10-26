############################################################################
# Private DNS (https://learn.microsoft.com/azure/dns/private-dns-overview) #
############################################################################

variable "privateDns" {
  type = object({
    enable   = bool
    zoneName = string
    autoRegistration = object({
      enable = bool
    })
  })
}

resource "azurerm_private_dns_zone" "studio" {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.name => virtualNetwork if var.privateDns.enable && !var.existingNetwork.enable
  }
  name                = var.privateDns.zoneName
  resource_group_name = each.value.resourceGroupName
  depends_on = [
    azurerm_virtual_network.studio
  ]
}

resource "azurerm_private_dns_zone_virtual_network_link" "studio" {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.name => virtualNetwork if var.privateDns.enable && !var.existingNetwork.enable
  }
  name                  = "studio-${lower(each.value.regionName)}"
  resource_group_name   = each.value.resourceGroupName
  private_dns_zone_name = azurerm_private_dns_zone.studio[each.value.name].name
  virtual_network_id    = each.value.id
  registration_enabled  = var.privateDns.autoRegistration.enable
  depends_on = [
    azurerm_virtual_network.studio
  ]
}

output "privateDns" {
  value = !var.existingNetwork.enable ? var.privateDns : null
}
