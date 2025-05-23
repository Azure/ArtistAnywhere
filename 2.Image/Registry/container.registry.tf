######################################################################################################
# Container Registry (https://learn.microsoft.com/azure/container-registry/container-registry-intro) #
######################################################################################################

variable containerRegistry {
  type = object({
    name = string
    tier = string
    adminUser = object({
      enable = bool
    })
    dataEndpoint = object({
      enable = bool
    })
    zoneRedundancy = object({
      enable = bool
    })
    quarantinePolicy = object({
      enable = bool
    })
    exportPolicy = object({
      enable = bool
    })
    trustPolicy = object({
      enable = bool
    })
    anonymousPull = object({
      enable = bool
    })
    encryption = object({
      enable = bool
    })
    retentionPolicy = object({
      days = number
    })
    firewallRules = list(object({
      action  = string
      ipRange = string
    }))
    replicationRegions = list(object({
      name = string
      regionEndpoint = object({
        enable = bool
      })
      zoneRedundancy = object({
        enable = bool
      })
    }))
    tasks = list(object({
      enable = bool
      name   = string
      type   = string
      docker = object({
        context = object({
          hostUrl     = string
          accessToken = string
        })
        filePath   = string
        imageNames = list(string)
        cache = object({
          enable = bool
        })
      })
      agentPool = object({
        enable = bool
        name   = string
      })
      timeout = object({
        seconds = number
      })
    }))
    agentPools = list(object({
      enable = bool
      name   = string
      type   = string
      count  = number
    }))
  })
}

resource azurerm_role_assignment container_registry_pull {
  role_definition_name = "AcrPull" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/containers#acrpull
  principal_id         = data.azurerm_user_assigned_identity.main.principal_id
  scope                = azurerm_container_registry.main.id
}

resource azurerm_container_registry main {
  name                          = var.containerRegistry.name
  resource_group_name           = azurerm_resource_group.image_registry.name
  location                      = azurerm_resource_group.image_registry.location
  sku                           = var.containerRegistry.tier
  admin_enabled                 = var.containerRegistry.adminUser.enable
  data_endpoint_enabled         = var.containerRegistry.dataEndpoint.enable
  zone_redundancy_enabled       = var.containerRegistry.zoneRedundancy.enable
  quarantine_policy_enabled     = var.containerRegistry.quarantinePolicy.enable
  retention_policy_in_days      = var.containerRegistry.retentionPolicy.days
  trust_policy_enabled          = var.containerRegistry.trustPolicy.enable
  export_policy_enabled         = var.containerRegistry.exportPolicy.enable
  public_network_access_enabled = var.containerRegistry.exportPolicy.enable
  anonymous_pull_enabled        = var.containerRegistry.anonymousPull.enable
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.main.id
    ]
  }
  network_rule_set {
    default_action = "Deny"
    ip_rule {
      action   = "Allow"
      ip_range = "${jsondecode(data.http.client_address.response_body).ip}/32"
    }
    dynamic ip_rule {
      for_each = var.containerRegistry.firewallRules
      content {
        action   = ip_rule.value.action
        ip_range = ip_rule.value.ipRange
      }
    }
  }
  dynamic encryption {
    for_each = var.containerRegistry.encryption.enable ? [1] : []
    content {
      key_vault_key_id   = azurerm_key_vault_key.main[data.terraform_remote_state.foundation.outputs.keyVault.keyName.dataEncryption].id
      identity_client_id = azurerm_user_assigned_identity.main.client_id
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

###############################################################################################
# Private Endpoint (https://learn.microsoft.com/azure/private-link/private-endpoint-overview) #
###############################################################################################

resource azurerm_private_dns_zone container_registry {
  name                = "privatelink.azurecr.io"
  resource_group_name = azurerm_resource_group.image_registry.name
}

resource azurerm_private_dns_zone_virtual_network_link container_registry {
  name                  = "container-registry"
  resource_group_name   = azurerm_private_dns_zone.container_registry.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.container_registry.name
  virtual_network_id    = data.azurerm_virtual_network.main.id
}

resource azurerm_private_endpoint container_registry {
  name                = "${lower(azurerm_container_registry.main.name)}-${azurerm_private_dns_zone_virtual_network_link.container_registry.name}"
  resource_group_name = azurerm_container_registry.main.resource_group_name
  location            = azurerm_container_registry.main.location
  subnet_id           = data.azurerm_subnet.main.id
  private_service_connection {
    name                           = azurerm_container_registry.main.name
    private_connection_resource_id = azurerm_container_registry.main.id
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
