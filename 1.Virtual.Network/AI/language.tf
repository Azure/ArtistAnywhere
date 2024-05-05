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
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  # network_acls {
  #   default_action = "Deny"
  #   virtual_network_rules {
  #     subnet_id = data.azurerm_subnet.ai.id
  #   }
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

resource azurerm_private_endpoint ai_language_conversational {
  for_each = {
    for subnet in local.virtualNetworksSubnetCompute : subnet.key => subnet if var.ai.language.conversational.enable && subnet.virtualNetworkEdgeZone == ""
  }
  name                = "${lower(each.value.virtualNetworkName)}-ai-language-conversational"
  resource_group_name = each.value.resourceGroupName
  location            = each.value.regionName
  subnet_id           = "${each.value.virtualNetworkId}/subnets/${each.value.name}"
  private_service_connection {
    name                           = azurerm_cognitive_account.ai_language_conversational[0].name
    private_connection_resource_id = azurerm_cognitive_account.ai_language_conversational[0].id
    is_manual_connection           = false
    subresource_names = [
      "account"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.ai[each.value.virtualNetworkKey].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.ai[0].id
    ]
  }
}

#########################################################################################
# AI Language (https://learn.microsoft.com/azure/ai-services/language-service/overview) #
#########################################################################################

resource azurerm_cognitive_account ai_text_analytics {
  count                                        = var.ai.language.textAnalytics.enable ? 1 : 0
  name                                         = var.ai.language.textAnalytics.name
  resource_group_name                          = azurerm_resource_group.ai.name
  location                                     = azurerm_resource_group.ai.location
  sku_name                                     = var.ai.language.textAnalytics.tier
  custom_subdomain_name                        = var.ai.language.textAnalytics.domainName != "" ? var.ai.language.textAnalytics.domainName : var.ai.language.textAnalytics.name
  custom_question_answering_search_service_id  = module.global.search.enable ? data.azurerm_search_service.studio[0].id : null
  custom_question_answering_search_service_key = module.global.search.enable ? data.azurerm_search_service.studio[0].query_keys[0].key : null
  kind                                         = "TextAnalytics"
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  network_acls {
    default_action = "Deny"
    virtual_network_rules {
      subnet_id = data.azurerm_subnet.ai.id
    }
    ip_rules = [
      jsondecode(data.http.client_address.response_body).ip
    ]
  }
  storage {
    storage_account_id = data.azurerm_storage_account.studio.id
  }
  dynamic customer_managed_key {
    for_each = module.global.keyVault.enable && var.ai.encryption.enable ? [1] : []
    content {
      key_vault_key_id = data.azurerm_key_vault_key.data_encryption[0].id
    }
  }
}

resource azurerm_private_endpoint ai_text_analytics {
  for_each = {
    for subnet in local.virtualNetworksSubnetCompute : subnet.key => subnet if var.ai.language.textAnalytics.enable && subnet.virtualNetworkEdgeZone == ""
  }
  name                = "${lower(each.value.virtualNetworkName)}-ai-text-analytics"
  resource_group_name = each.value.resourceGroupName
  location            = each.value.regionName
  subnet_id           = "${each.value.virtualNetworkId}/subnets/${each.value.name}"
  private_service_connection {
    name                           = azurerm_cognitive_account.ai_text_analytics[0].name
    private_connection_resource_id = azurerm_cognitive_account.ai_text_analytics[0].id
    is_manual_connection           = false
    subresource_names = [
      "account"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.ai[each.value.virtualNetworkKey].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.ai[0].id
    ]
  }
}

################################################################################################
# AI Translation (https://learn.microsoft.com/azure/ai-services/translator/translator-overview) #
################################################################################################

resource azurerm_cognitive_account ai_text_translation {
  count                 = var.ai.language.textTranslation.enable ? 1 : 0
  name                  = var.ai.language.textTranslation.name
  resource_group_name   = azurerm_resource_group.ai.name
  location              = azurerm_resource_group.ai.location
  sku_name              = var.ai.language.textTranslation.tier
  custom_subdomain_name = var.ai.language.textTranslation.domainName != "" ? var.ai.language.textTranslation.domainName : var.ai.language.textTranslation.name
  kind                  = "TextTranslation"
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  network_acls {
    default_action = "Deny"
    virtual_network_rules {
      subnet_id = data.azurerm_subnet.ai.id
    }
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

resource azurerm_private_endpoint ai_text_translation {
  for_each = {
    for subnet in local.virtualNetworksSubnetCompute : subnet.key => subnet if var.ai.language.textTranslation.enable && subnet.virtualNetworkEdgeZone == ""
  }
  name                = "${lower(each.value.virtualNetworkName)}-ai-text-translation"
  resource_group_name = each.value.resourceGroupName
  location            = each.value.regionName
  subnet_id           = "${each.value.virtualNetworkId}/subnets/${each.value.name}"
  private_service_connection {
    name                           = azurerm_cognitive_account.ai_text_translation[0].name
    private_connection_resource_id = azurerm_cognitive_account.ai_text_translation[0].id
    is_manual_connection           = false
    subresource_names = [
      "account"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.ai[each.value.virtualNetworkKey].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.ai[0].id
    ]
  }
}
