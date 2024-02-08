######################################################################################################
# Container Registry (https://learn.microsoft.com/azure/container-registry/container-registry-intro) #
######################################################################################################

variable containerRegistry {
  type = object({
    enable = bool
    name   = string
    sku    = string
    adminUser = object({
      enable = bool
    })
    zoneRedundancy = object({
      enable = bool
    })
  })
}

# resource azurerm_private_dns_zone container_registry {
#   count               = var.containerRegistry.enable ? 1 : 0
#   name                = "privatelink.azurecr.io"
#   resource_group_name = azurerm_resource_group.image.name
# }

# resource azurerm_private_dns_zone_virtual_network_link container_registry {
#   count                 = var.containerRegistry.enable ? 1 : 0
#   name                  = "container-registry-${lower(data.azurerm_virtual_network.studio.location)}"
#   resource_group_name   = azurerm_resource_group.image.name
#   private_dns_zone_name = azurerm_private_dns_zone.container_registry[0].name
#   virtual_network_id    = data.azurerm_virtual_network.studio.id
# }

# resource azurerm_private_endpoint container_registry {
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
#       azurerm_private_dns_zone.container_registry[0].id
#     ]
#   }
#   depends_on = [
#     azurerm_private_dns_zone_virtual_network_link.container_registry
#   ]
# }

resource azurerm_container_registry studio {
  count                   = var.containerRegistry.enable ? 1 : 0
  name                    = var.containerRegistry.name
  resource_group_name     = azurerm_resource_group.image.name
  location                = azurerm_resource_group.image.location
  sku                     = var.containerRegistry.sku
  admin_enabled           = var.containerRegistry.adminUser.enable
  zone_redundancy_enabled = var.containerRegistry.zoneRedundancy.enable
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  # network_rule_set {
  #   default_action = "Deny"
  #   virtual_network {
  #     action    = "Allow"
  #     subnet_id = data.azurerm_subnet.farm.id
  #   }
  #   ip_rule {
  #     action   = "Allow"
  #     ip_range = jsondecode(data.http.client_address.response_body).ip
  #   }
  # }
}

resource azurerm_container_registry_task lnx_farmc_cmake {
  count                 = var.containerRegistry.enable ? 1 : 0
  name                  = "LnxFarmC-CMake"
  container_registry_id = azurerm_container_registry.studio[0].id
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  platform {
    os = "Linux"
  }
  docker_step {
    context_access_token = " "
    context_path         = "https://github.com/Azure/ArtistAnywhere.git"
    dockerfile_path      = "2.Image.Builder/docker/LnxFarmC-CMake"
    image_names          = ["lnx-farm-c:cmake"]
    cache_enabled        = false
  }
  timeout_in_seconds = 3600
}

resource azurerm_container_registry_task lnx_farmc_pbrt {
  count                 = var.containerRegistry.enable ? 1 : 0
  name                  = "LnxFarmC-PBRT"
  container_registry_id = azurerm_container_registry.studio[0].id
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  platform {
    os = "Linux"
  }
  docker_step {
    context_access_token = " "
    context_path         = "https://github.com/Azure/ArtistAnywhere.git"
    dockerfile_path      = "2.Image.Builder/docker/LnxFarmC-PBRT"
    image_names          = ["lnx-farm-c:pbrt"]
    cache_enabled        = false
  }
  timeout_in_seconds = 3600
}

resource azurerm_container_registry_task lnx_farmc_moonray {
  count                 = var.containerRegistry.enable ? 1 : 0
  name                  = "LnxFarmC-MoonRay"
  container_registry_id = azurerm_container_registry.studio[0].id
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  platform {
    os = "Linux"
  }
  docker_step {
    context_access_token = " "
    context_path         = "https://github.com/Azure/ArtistAnywhere.git"
    dockerfile_path      = "2.Image.Builder/docker/LnxFarmC-MoonRay"
    image_names          = ["lnx-farm-c:moonray"]
    cache_enabled        = false
  }
  timeout_in_seconds = 14400
}

resource azurerm_container_registry_task win_farmc_cmake {
  count                 = var.containerRegistry.enable ? 1 : 0
  name                  = "WinFarmC-CMake"
  container_registry_id = azurerm_container_registry.studio[0].id
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  platform {
    os = "Windows"
  }
  docker_step {
    context_access_token = " "
    context_path         = "https://github.com/Azure/ArtistAnywhere.git"
    dockerfile_path      = "2.Image.Builder/docker/WinFarmC-CMake"
    image_names          = ["win-farm-c:cmake"]
    cache_enabled        = false
  }
  timeout_in_seconds = 3600
}

resource azurerm_container_registry_task win_farmc_pbrt {
  count                 = var.containerRegistry.enable ? 1 : 0
  name                  = "WinFarmC-PBRT"
  container_registry_id = azurerm_container_registry.studio[0].id
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  platform {
    os = "Windows"
  }
  docker_step {
    context_access_token = " "
    context_path         = "https://github.com/Azure/ArtistAnywhere.git"
    dockerfile_path      = "2.Image.Builder/docker/WinFarmC-PBRT"
    image_names          = ["win-farm-c:pbrt"]
    cache_enabled        = false
  }
  timeout_in_seconds = 3600
}
