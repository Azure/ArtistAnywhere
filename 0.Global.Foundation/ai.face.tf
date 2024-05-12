#############################################################################################
# AI Face (https://learn.microsoft.com/azure/ai-services/computer-vision/overview-identity) #
#############################################################################################

resource azurerm_cognitive_account ai_face {
  count                 = var.ai.face.enable && module.global.ai.enable ? 1 : 0
  name                  = var.ai.face.name
  resource_group_name   = azurerm_resource_group.studio_ai[0].name
  location              = azurerm_resource_group.studio_ai[0].location
  sku_name              = var.ai.face.tier
  custom_subdomain_name = var.ai.face.domainName != "" ? var.ai.face.domainName : var.ai.face.name
  kind                  = "Face"
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
