######################################################################################################
# Container Registry (https://learn.microsoft.com/azure/container-registry/container-registry-intro) #
######################################################################################################

variable containerRegistry {
  type = object({
    enable = bool
    name   = string
    type   = string
    adminUser = object({
      enable = bool
    })
    agentPool = object({
      enable        = bool
      tier          = string
      instanceCount = number
    })
  })
}

resource azurerm_container_registry studio {
  count               = var.containerRegistry.enable ? 1 : 0
  name                = var.containerRegistry.name
  resource_group_name = azurerm_resource_group.image_registry[0].name
  location            = azurerm_resource_group.image_registry[0].location
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
    for_each = {
      for regionName in local.regionNames : regionName => regionName if lower(regionName) != lower(module.global.resourceLocation.regionName)
    }
    content {
      location                  = georeplications.value
      regional_endpoint_enabled = true
      zone_redundancy_enabled   = false
    }
  }
}

resource azurerm_container_registry_agent_pool studio {
  count                     = var.containerRegistry.enable && var.containerRegistry.agentPool.enable ? 1 : 0
  name                      = var.containerRegistry.name
  resource_group_name       = azurerm_resource_group.image_registry[0].name
  location                  = azurerm_resource_group.image_registry[0].location
  container_registry_name   = azurerm_container_registry.studio[0].name
  tier                      = var.containerRegistry.agentPool.tier
  instance_count            = var.containerRegistry.agentPool.instanceCount
  virtual_network_subnet_id = data.azurerm_subnet.farm.id
}

resource azurerm_private_dns_zone container_registry {
  count               = var.containerRegistry.enable ? 1 : 0
  name                = "privatelink.azurecr.io"
  resource_group_name = azurerm_resource_group.image_registry[0].name
}

resource azurerm_private_dns_zone_virtual_network_link container_registry {
  count                 = var.containerRegistry.enable ? 1 : 0
  name                  = "registry"
  resource_group_name   = azurerm_private_dns_zone.container_registry[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.container_registry[0].name
  virtual_network_id    = data.azurerm_virtual_network.studio_region.id
}

resource azurerm_private_endpoint container_registry {
  count               = var.containerRegistry.enable ? 1 : 0
  name                = "${azurerm_container_registry.studio[0].name}-${azurerm_private_dns_zone_virtual_network_link.container_registry[0].name}"
  resource_group_name = azurerm_resource_group.image_registry[0].name
  location            = azurerm_resource_group.image_registry[0].location
  subnet_id           = data.azurerm_subnet.farm.id
  private_service_connection {
    name                           = azurerm_container_registry.studio[0].name
    private_connection_resource_id = azurerm_container_registry.studio[0].id
    is_manual_connection           = false
    subresource_names = [
      "registry"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.container_registry[0].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.container_registry[0].id
    ]
  }
}

resource azurerm_eventgrid_system_topic container_registry {
  count                  = var.containerRegistry.enable ? 1 : 0
  name                   = azurerm_container_registry.studio[0].name
  resource_group_name    = azurerm_container_registry.studio[0].resource_group_name
  location               = azurerm_container_registry.studio[0].location
  source_arm_resource_id = azurerm_container_registry.studio[0].id
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
    context_path         = "https://github.com/Azure/ArtistAnywhere.git"
    dockerfile_path      = "2.Image.Builder/Docker/LnxFarmC-CMake"
    image_names          = ["lnx-farm-c:cmake"]
    cache_enabled        = false
    context_access_token = " "
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
    context_path         = "https://github.com/Azure/ArtistAnywhere.git"
    dockerfile_path      = "2.Image.Builder/Docker/LnxFarmC-PBRT"
    image_names          = ["lnx-farm-c:pbrt"]
    cache_enabled        = false
    context_access_token = " "
  }
  timeout_in_seconds = 3600
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
    context_path         = "https://github.com/Azure/ArtistAnywhere.git"
    dockerfile_path      = "2.Image.Builder/Docker/WinFarmC-CMake"
    image_names          = ["win-farm-c:cmake"]
    cache_enabled        = false
    context_access_token = " "
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
    context_path         = "https://github.com/Azure/ArtistAnywhere.git"
    dockerfile_path      = "2.Image.Builder/Docker/WinFarmC-PBRT"
    image_names          = ["win-farm-c:pbrt"]
    cache_enabled        = false
    context_access_token = " "
  }
  timeout_in_seconds = 3600
}
