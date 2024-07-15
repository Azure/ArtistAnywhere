############################################################################################################################################################
# AI Conversational Language Understanding (https://learn.microsoft.com/azure/ai-services/language-service/conversational-language-understanding/overview) #
############################################################################################################################################################

resource azurerm_cognitive_account ai_language_conversational {
  count                 = var.ai.language.conversational.enable ? 1 : 0
  name                  = var.ai.language.conversational.name
  resource_group_name   = azurerm_resource_group.ai.name
  location              = azurerm_resource_group.ai.location
  sku_name              = var.ai.language.conversational.tier
  custom_subdomain_name = var.ai.language.conversational.domainName != "" ? var.ai.language.conversational.domainName : var.ai.language.conversational.name
  kind                  = "ConversationalLanguageUnderstanding"
  local_auth_enabled    = false
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  # network_acls {
  #   default_action = "Deny"
  #   ip_rules = [
  #     jsondecode(data.http.client_address.response_body).ip
  #   ]
  # }
  dynamic customer_managed_key {
    for_each = module.global.keyVault.enable && var.ai.encryption.enable ? [1] : []
    content {
      key_vault_key_id = data.azurerm_key_vault_key.data_encryption[0].id
    }
  }
}

#########################################################################################
# AI Language (https://learn.microsoft.com/azure/ai-services/language-service/overview) #
#########################################################################################

resource azurerm_cognitive_account ai_language_text_analytics {
  count                                        = var.ai.language.textAnalytics.enable ? 1 : 0
  name                                         = var.ai.language.textAnalytics.name
  resource_group_name                          = azurerm_resource_group.ai.name
  location                                     = azurerm_resource_group.ai.location
  sku_name                                     = var.ai.language.textAnalytics.tier
  custom_subdomain_name                        = var.ai.language.textAnalytics.domainName != "" ? var.ai.language.textAnalytics.domainName : var.ai.language.textAnalytics.name
  custom_question_answering_search_service_id  = var.ai.search.enable ? azurerm_search_service.ai[0].id : null
  custom_question_answering_search_service_key = var.ai.search.enable ? azurerm_search_service.ai[0].query_keys[0].key : null
  kind                                         = "TextAnalytics"
  local_auth_enabled                           = false
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
    for_each = module.global.keyVault.enable && var.ai.encryption.enable ? [1] : []
    content {
      key_vault_key_id   = data.azurerm_key_vault_key.data_encryption[0].id
      identity_client_id = data.azurerm_user_assigned_identity.studio.client_id
    }
  }
}

################################################################################################
# AI Translation (https://learn.microsoft.com/azure/ai-services/translator/translator-overview) #
################################################################################################

resource azurerm_cognitive_account ai_language_text_translation {
  count                 = var.ai.language.textTranslation.enable ? 1 : 0
  name                  = var.ai.language.textTranslation.name
  resource_group_name   = azurerm_resource_group.ai.name
  location              = azurerm_resource_group.ai.location
  sku_name              = var.ai.language.textTranslation.tier
  custom_subdomain_name = var.ai.language.textTranslation.domainName != "" ? var.ai.language.textTranslation.domainName : var.ai.language.textTranslation.name
  kind                  = "TextTranslation"
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
