######################################################################################################
# Container Registry (https://learn.microsoft.com/azure/container-registry/container-registry-intro) #
######################################################################################################

variable containerRegistry {
  type = object({
    name = string
    type = string
    adminUser = object({
      enable = bool
    })
    tasks = object({
      enable = bool
    })
  })
}

resource azurerm_container_registry studio {
  name                = var.containerRegistry.name
  resource_group_name = azurerm_resource_group.image_docker.name
  location            = azurerm_resource_group.image_docker.location
  sku                 = var.containerRegistry.type
  admin_enabled       = var.containerRegistry.adminUser.enable
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  network_rule_set {
    default_action = "Deny"
    ip_rule {
      action   = "Allow"
      ip_range = "${jsondecode(data.http.client_address.response_body).ip}/32"
    }
  }
  dynamic georeplications {
    for_each = local.regionNames
    content {
      location                  = georeplications.value
      regional_endpoint_enabled = true
      zone_redundancy_enabled   = false
    }
  }
}

resource azurerm_private_dns_zone container_registry {
  name                = "privatelink.azurecr.io"
  resource_group_name = azurerm_resource_group.image_docker.name
}

resource azurerm_private_dns_zone_virtual_network_link container_registry {
  name                  = "registry"
  resource_group_name   = azurerm_private_dns_zone.container_registry.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.container_registry.name
  virtual_network_id    = data.azurerm_virtual_network.studio_region.id
}

resource azurerm_private_endpoint container_registry {
  name                = "${azurerm_container_registry.studio.name}-${azurerm_private_dns_zone_virtual_network_link.container_registry.name}"
  resource_group_name = azurerm_resource_group.image_docker.name
  location            = azurerm_resource_group.image_docker.location
  subnet_id           = data.azurerm_subnet.farm.id
  private_service_connection {
    name                           = azurerm_container_registry.studio.name
    private_connection_resource_id = azurerm_container_registry.studio.id
    is_manual_connection           = false
    subresource_names = [
      "registry"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.container_registry.name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.container_registry.id
    ]
  }
}

resource azurerm_eventgrid_system_topic container_registry {
  name                   = azurerm_container_registry.studio.name
  resource_group_name    = azurerm_container_registry.studio.resource_group_name
  location               = azurerm_container_registry.studio.location
  source_arm_resource_id = azurerm_container_registry.studio.id
  topic_type             = "Microsoft.ContainerRegistry.Registries"
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
}

##########################################################################################
# https://learn.microsoft.com/azure/container-registry/container-registry-tasks-overview #
##########################################################################################

resource azurerm_container_registry_task lnx_farmc_cmake {
  count                 = var.containerRegistry.tasks.enable ? 1 : 0
  name                  = "LnxFarmC-CMake"
  container_registry_id = azurerm_container_registry.studio.id
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
    dockerfile_path      = "2.Image.Builder/Docker/LnxFarm/LnxFarmC-CMake"
    image_names          = ["lnx-farm-c:cmake"]
    cache_enabled        = false
  }
  timeout_in_seconds = 3600
}

resource azurerm_container_registry_task lnx_farmc_pbrt {
  count                 = var.containerRegistry.tasks.enable ? 1 : 0
  name                  = "LnxFarmC-PBRT"
  container_registry_id = azurerm_container_registry.studio.id
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
    dockerfile_path      = "2.Image.Builder/Docker/LnxFarm/LnxFarmC-PBRT"
    image_names          = ["lnx-farm-c:pbrt"]
    cache_enabled        = false
  }
  timeout_in_seconds = 3600
}

resource azurerm_container_registry_task lnx_farmc_moonray {
  count                 = var.containerRegistry.tasks.enable ? 1 : 0
  name                  = "LnxFarmC-MoonRay"
  container_registry_id = azurerm_container_registry.studio.id
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
    dockerfile_path      = "2.Image.Builder/Docker/LnxFarm/LnxFarmC-MoonRay"
    image_names          = ["lnx-farm-c:moonray"]
    cache_enabled        = false
  }
  timeout_in_seconds = 14400
}

resource azurerm_container_registry_task win_farmc_cmake {
  count                 = var.containerRegistry.tasks.enable ? 1 : 0
  name                  = "WinFarmC-CMake"
  container_registry_id = azurerm_container_registry.studio.id
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
    dockerfile_path      = "2.Image.Builder/Docker/WinFarm/WinFarmC-CMake"
    image_names          = ["win-farm-c:cmake"]
    cache_enabled        = false
  }
  timeout_in_seconds = 3600
}

resource azurerm_container_registry_task win_farmc_pbrt {
  count                 = var.containerRegistry.tasks.enable ? 1 : 0
  name                  = "WinFarmC-PBRT"
  container_registry_id = azurerm_container_registry.studio.id
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
    dockerfile_path      = "2.Image.Builder/Docker/WinFarm/WinFarmC-PBRT"
    image_names          = ["win-farm-c:pbrt"]
    cache_enabled        = false
  }
  timeout_in_seconds = 3600
}
