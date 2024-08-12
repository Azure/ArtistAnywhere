#####################################################################################
# AI Speech (https://learn.microsoft.com/azure/ai-services/speech-service/overview) #
#####################################################################################

resource azurerm_cognitive_account ai_speech {
  count                 = var.ai.speech.enable ? 1 : 0
  name                  = var.ai.speech.name
  resource_group_name   = azurerm_resource_group.ai.name
  location              = azurerm_resource_group.ai.location
  sku_name              = var.ai.speech.tier
  custom_subdomain_name = var.ai.speech.domainName != "" ? var.ai.speech.domainName : var.ai.speech.name
  kind                  = "SpeechServices"
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
  storage {
    storage_account_id = data.azurerm_storage_account.studio.id
    identity_client_id = data.azurerm_user_assigned_identity.studio.client_id
  }
  dynamic customer_managed_key {
    for_each = var.ai.encryption.enable ? [1] : []
    content {
      key_vault_key_id   = data.azurerm_key_vault_key.data_encryption.id
      identity_client_id = data.azurerm_user_assigned_identity.studio.client_id
    }
  }
}
