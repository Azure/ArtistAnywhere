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
  count                         = var.containerRegistry.enable ? 1 : 0
  name                          = var.containerRegistry.name
  resource_group_name           = azurerm_resource_group.image_registry[0].name
  location                      = azurerm_resource_group.image_registry[0].location
  sku                           = var.containerRegistry.type
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

###############################################################################################
# Private Endpoint (https://learn.microsoft.com/azure/private-link/private-endpoint-overview) #
###############################################################################################

resource azurerm_private_dns_zone container_registry {
  count               = var.containerRegistry.enable ? 1 : 0
  name                = "privatelink.azurecr.io"
  resource_group_name = azurerm_resource_group.image_registry[0].name
}

resource azurerm_private_dns_zone_virtual_network_link container_registry {
  count                 = var.containerRegistry.enable ? 1 : 0
  name                  = "container-registry"
  resource_group_name   = azurerm_private_dns_zone.container_registry[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.container_registry[0].name
  virtual_network_id    = data.azurerm_virtual_network.studio.id
}

resource azurerm_private_endpoint container_registry {
  count               = var.containerRegistry.enable ? 1 : 0
  name                = "${lower(azurerm_container_registry.studio[0].name)}-${azurerm_private_dns_zone_virtual_network_link.container_registry[0].name}"
  resource_group_name = azurerm_container_registry.studio[0].resource_group_name
  location            = azurerm_container_registry.studio[0].location
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

output containerRegistry {
  value = var.containerRegistry.enable ? {
    id = azurerm_container_registry.studio[0].id
  } : null
}
