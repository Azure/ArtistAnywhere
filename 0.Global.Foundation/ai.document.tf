###########################################################################################################
# AI Document Intelligence (https://learn.microsoft.com/azure/ai-services/document-intelligence/overview) #
###########################################################################################################

resource azurerm_cognitive_account ai_document {
  count                 = var.ai.document.enable && module.global.ai.enable ? 1 : 0
  name                  = var.ai.document.name
  resource_group_name   = azurerm_resource_group.studio_ai[0].name
  location              = azurerm_resource_group.studio_ai[0].location
  sku_name              = var.ai.document.tier
  custom_subdomain_name = var.ai.document.domainName != "" ? var.ai.document.domainName : var.ai.document.name
  kind                  = "FormRecognizer"
  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.studio.id
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
      key_vault_key_id = azurerm_key_vault_key.data_encryption[0].id
    }
  }
}
