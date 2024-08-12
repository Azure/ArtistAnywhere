##########################################################################################
# App Configuration (https://learn.microsoft.com/azure/azure-app-configuration/overview) #
##########################################################################################

variable appConfig {
  type = object({
    tier = string
    encryption = object({
      enable = bool
    })
  })
}

resource azurerm_app_configuration studio {
  name                = module.global.appConfig.name
  resource_group_name = azurerm_resource_group.studio.name
  location            = azurerm_resource_group.studio.location
  sku                 = var.appConfig.tier
  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.studio.id
    ]
  }
  dynamic encryption {
    for_each = var.appConfig.encryption.enable ? [1] : []
    content {
      key_vault_key_identifier = azurerm_key_vault_key.studio[module.global.keyVault.keyName.dataEncryption].id
      identity_client_id       = azurerm_user_assigned_identity.studio.client_id
    }
  }
}
