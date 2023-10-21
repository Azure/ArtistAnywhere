#####################################################################################################
# Container Registry (https://learn.microsoft.com/azure/container-registry/container-registry-intro) #
#####################################################################################################

variable "containerRegistry" {
  type = object({
    enable = bool
    name   = string
    sku    = string
  })
}

# resource "azurerm_private_dns_zone" "registry" {
#   count               = var.containerRegistry.enable ? 1 : 0
#   name                = "privatelink.azurecr.io"
#   resource_group_name = azurerm_resource_group.image.name
# }

# resource "azurerm_private_dns_zone_virtual_network_link" "registry" {
#   count                 = var.containerRegistry.enable ? 1 : 0
#   name                  = "${azurerm_container_registry.studio[0].name}-registry"
#   resource_group_name   = azurerm_resource_group.image.name
#   private_dns_zone_name = azurerm_private_dns_zone.registry[0].name
#   virtual_network_id    = data.azurerm_virtual_network.compute.id
# }

# resource "azurerm_private_endpoint" "farm" {
#   count               = var.containerRegistry.enable ? 1 : 0
#   name                = "${azurerm_container_registry.studio[0].name}-registry"
#   resource_group_name = azurerm_resource_group.image.name
#   location            = azurerm_resource_group.image.location
#   subnet_id           = data.azurerm_subnet.farm.id
#   private_service_connection {
#     name                           = azurerm_container_registry.studio[0].name
#     private_connection_resource_id = azurerm_container_registry.studio[0].id
#     is_manual_connection           = false
#     subresource_names = [
#       "registry"
#     ]
#   }
#   private_dns_zone_group {
#     name = azurerm_container_registry.studio[0].name
#     private_dns_zone_ids = [
#       azurerm_private_dns_zone.registry[0].id
#     ]
#   }
# }

# resource "azurerm_container_registry" "studio" {
#   count               = var.containerRegistry.enable ? 1 : 0
#   name                = var.containerRegistry.name
#   resource_group_name = azurerm_resource_group.image.name
#   location            = azurerm_resource_group.image.location
#   sku                 = var.containerRegistry.sku
#   identity {
#     type = "UserAssigned"
#     identity_ids = [
#       data.azurerm_user_assigned_identity.studio.id
#     ]
#   }
#   network_rule_set {
#     default_action = "Deny"
#     virtual_network {
#       action    = "Allow"
#       subnet_id = data.azurerm_subnet.farm.id
#     }
#     ip_rule {
#       action   = "Allow"
#       ip_range = jsondecode(data.http.client_address.response_body).ip
#     }
#   }
# }
