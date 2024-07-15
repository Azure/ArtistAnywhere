#################################################################################################
# AI Immersive Reader (https://learn.microsoft.com/azure/ai-services/immersive-reader/overview) #
#################################################################################################

resource azurerm_cognitive_account ai_immersive_reader {
  count                 = var.ai.immersiveReader.enable ? 1 : 0
  name                  = var.ai.immersiveReader.name
  resource_group_name   = azurerm_resource_group.ai.name
  location              = azurerm_resource_group.ai.location
  sku_name              = var.ai.immersiveReader.tier
  custom_subdomain_name = var.ai.immersiveReader.domainName != "" ? var.ai.immersiveReader.domainName : var.ai.immersiveReader.name
  kind                  = "ImmersiveReader"
  local_auth_enabled    = false
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
