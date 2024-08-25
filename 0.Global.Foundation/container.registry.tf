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
    encryption = object({
      enable = bool
    })
    quarantinePolicy = object({
      enable = bool
    })
    zoneRedundancy = object({
      enable = bool
    })
    dataEndpoint = object({
      enable = bool
    })
    trustPolicy = object({
      enable = bool
    })
    retentionPolicy = object({
      days = number
    })
    agentPool = object({
      enable        = bool
      tier          = string
      instanceCount = number
    })
    replicationRegions = list(object({
      name = string
      regionEndpoint = object({
        enable = bool
      })
      zoneRedundancy = object({
        enable = bool
      })
    }))
  })
}

resource azurerm_container_registry studio {
  count                     = var.containerRegistry.enable ? 1 : 0
  name                      = var.containerRegistry.name
  resource_group_name       = azurerm_resource_group.studio_registry[0].name
  location                  = azurerm_resource_group.studio_registry[0].location
  sku                       = var.containerRegistry.type
  admin_enabled             = var.containerRegistry.adminUser.enable
  data_endpoint_enabled     = var.containerRegistry.dataEndpoint.enable
  zone_redundancy_enabled   = var.containerRegistry.zoneRedundancy.enable
  quarantine_policy_enabled = var.containerRegistry.quarantinePolicy.enable
  retention_policy_in_days  = var.containerRegistry.retentionPolicy.days
  trust_policy_enabled      = var.containerRegistry.trustPolicy.enable
  anonymous_pull_enabled    = false
  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.studio.id
    ]
  }
  network_rule_set {
    default_action = "Deny"
    ip_rule {
      action   = "Allow"
      ip_range = "${jsondecode(data.http.client_address.response_body).ip}/32"
    }
  }
  dynamic encryption {
    for_each = var.containerRegistry.encryption.enable ? [1] : []
    content {
      key_vault_key_id   = azurerm_key_vault_key.studio[module.global.keyVault.keyName.dataEncryption].id
      identity_client_id = azurerm_user_assigned_identity.studio.client_id
    }
  }
  dynamic georeplications {
    for_each = var.containerRegistry.replicationRegions
    content {
      location                  = georeplications.value.name
      regional_endpoint_enabled = georeplications.value.regionEndpoint.enable
      zone_redundancy_enabled   = georeplications.value.zoneRedundancy.enable
    }
  }
}

resource azurerm_container_registry_agent_pool studio {
  count                     = var.containerRegistry.enable && var.containerRegistry.agentPool.enable ? 1 : 0
  name                      = var.containerRegistry.name
  resource_group_name       = azurerm_resource_group.studio_registry[0].name
  location                  = azurerm_resource_group.studio_registry[0].location
  container_registry_name   = azurerm_container_registry.studio[0].name
  tier                      = var.containerRegistry.agentPool.tier
  instance_count            = var.containerRegistry.agentPool.instanceCount
  #virtual_network_subnet_id = data.azurerm_subnet.farm.id
}

# resource azurerm_eventgrid_system_topic container_registry {
#   name                   = azurerm_container_registry.studio.name
#   resource_group_name    = azurerm_container_registry.studio.resource_group_name
#   location               = azurerm_container_registry.studio.location
#   source_arm_resource_id = azurerm_container_registry.studio.id
#   topic_type             = "Microsoft.ContainerRegistry.Registries"
#   identity {
#     type = "UserAssigned"
#     identity_ids = [
#       data.azurerm_user_assigned_identity.studio.id
#     ]
#   }
# }

##########################################################################################
# https://learn.microsoft.com/azure/container-registry/container-registry-tasks-overview #
##########################################################################################

# resource azurerm_container_registry_task lnx_farmc_cmake {
#   name                  = "LnxFarmC-CMake"
#   container_registry_id = azurerm_container_registry.studio.id
#   identity {
#     type = "UserAssigned"
#     identity_ids = [
#       data.azurerm_user_assigned_identity.studio.id
#     ]
#   }
#   platform {
#     os = "Linux"
#   }
#   docker_step {
#     context_path         = "https://github.com/Azure/ArtistAnywhere.git"
#     dockerfile_path      = "2.Image.Builder/Docker/LnxFarmC-CMake"
#     image_names          = ["lnx-farm-c:cmake"]
#     cache_enabled        = false
#     context_access_token = " "
#   }
#   timeout_in_seconds = 3600
# }

# resource azurerm_container_registry_task lnx_farmc_pbrt {
#   name                  = "LnxFarmC-PBRT"
#   container_registry_id = azurerm_container_registry.studio.id
#   identity {
#     type = "UserAssigned"
#     identity_ids = [
#       data.azurerm_user_assigned_identity.studio.id
#     ]
#   }
#   platform {
#     os = "Linux"
#   }
#   docker_step {
#     context_path         = "https://github.com/Azure/ArtistAnywhere.git"
#     dockerfile_path      = "2.Image.Builder/Docker/LnxFarmC-PBRT"
#     image_names          = ["lnx-farm-c:pbrt"]
#     cache_enabled        = false
#     context_access_token = " "
#   }
#   timeout_in_seconds = 3600
# }

# resource azurerm_container_registry_task win_farmc_cmake {
#   name                  = "WinFarmC-CMake"
#   container_registry_id = azurerm_container_registry.studio.id
#   identity {
#     type = "UserAssigned"
#     identity_ids = [
#       data.azurerm_user_assigned_identity.studio.id
#     ]
#   }
#   platform {
#     os = "Windows"
#   }
#   docker_step {
#     context_path         = "https://github.com/Azure/ArtistAnywhere.git"
#     dockerfile_path      = "2.Image.Builder/Docker/WinFarmC-CMake"
#     image_names          = ["win-farm-c:cmake"]
#     cache_enabled        = false
#     context_access_token = " "
#   }
#   timeout_in_seconds = 3600
# }

# resource azurerm_container_registry_task win_farmc_pbrt {
#   name                  = "WinFarmC-PBRT"
#   container_registry_id = azurerm_container_registry.studio.id
#   identity {
#     type = "UserAssigned"
#     identity_ids = [
#       data.azurerm_user_assigned_identity.studio.id
#     ]
#   }
#   platform {
#     os = "Windows"
#   }
#   docker_step {
#     context_path         = "https://github.com/Azure/ArtistAnywhere.git"
#     dockerfile_path      = "2.Image.Builder/Docker/WinFarmC-PBRT"
#     image_names          = ["win-farm-c:pbrt"]
#     cache_enabled        = false
#     context_access_token = " "
#   }
#   timeout_in_seconds = 3600
# }

output containerRegistry {
  value = {
    enable            = var.containerRegistry.enable
    id                = var.containerRegistry.enable ? azurerm_container_registry.studio[0].id : null
    name              = var.containerRegistry.enable ? azurerm_container_registry.studio[0].name : null
    regionName        = var.containerRegistry.enable ? azurerm_resource_group.studio_registry[0].location : null
    resourceGroupName = var.containerRegistry.enable ? azurerm_resource_group.studio_registry[0].name : null
  }
}
