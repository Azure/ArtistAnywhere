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
  count               = module.global.appConfig.enable ? 1 : 0
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
    for_each = module.global.keyVault.enable && var.appConfig.encryption.enable ? [1] : []
    content {
      key_vault_key_identifier = azurerm_key_vault_key.studio[module.global.keyVault.keyNames.cacheEncryption].id
    }
  }
}
