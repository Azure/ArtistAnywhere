######################################################################################################################
# Application Gateway                (https://learn.microsoft.com/azure/application-gateway/overview-v2)             #
# Application Gateway for Containers (https://learn.microsoft.com/azure/application-gateway/for-containers/overview) #
######################################################################################################################

variable appGateway {
  type = object({
    enable   = bool
    name     = string
    type     = string
    tier     = string
    capacity = number
  })
}

# resource azurerm_application_gateway studio {
#   for_each = {
#     for virtualNetwork in local.virtualNetworks : virtualNetwork.key => virtualNetwork
#   }
#   name                = var.appGateway.name
#   resource_group_name = each.value.resourceGroup.name
#   location            = each.value.location
#   sku {
#     name     = var.appGateway.type
#     tier     = var.appGateway.tier
#     capacity = var.appGateway.capacity
#   }
#   depends_on = [
#     azurerm_resource_group.network_regions
#   ]
# }
