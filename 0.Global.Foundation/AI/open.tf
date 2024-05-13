##########################################################################
# OpenAI (https://learn.microsoft.com/azure/ai-services/openai/overview) #
##########################################################################

resource azurerm_cognitive_account ai_open {
  count                 = var.ai.open.enable ? 1 : 0
  name                  = var.ai.open.name
  resource_group_name   = azurerm_resource_group.studio_ai.name
  location              = azurerm_resource_group.studio_ai.location
  sku_name              = var.ai.open.tier
  custom_subdomain_name = var.ai.open.domainName != "" ? var.ai.open.domainName : var.ai.open.name
  kind                  = "OpenAI"
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  network_acls {
    default_action = "Deny"
    ip_rules = [
      jsondecode(data.http.client_address.response_body).ip
    ]
  }
  dynamic customer_managed_key {
    for_each = module.global.keyVault.enable && var.ai.encryption.enable ? [1] : []
    content {
      key_vault_key_id = data.azurerm_key_vault_key.data_encryption[0].id
    }
  }
}
