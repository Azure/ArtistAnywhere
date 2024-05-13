#################################################################################
# AI Bot Framework Composer (https://learn.microsoft.com/composer/introduction) #
#################################################################################

resource azurerm_bot_service_azure_bot ai {
  count               = var.ai.bot.enable ? 1 : 0
  name                = var.ai.bot.name
  display_name        = var.ai.bot.displayName != "" ? var.ai.bot.displayName : null
  resource_group_name = azurerm_resource_group.studio_ai.name
  location            = "Global"
  sku                 = var.ai.bot.tier
  microsoft_app_id    = var.ai.bot.applicationId
}
