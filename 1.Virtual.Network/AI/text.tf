#########################################################################################
# AI Language (https://learn.microsoft.com/azure/ai-services/language-service/overview) #
#########################################################################################

resource azurerm_cognitive_account ai_text_analytics {
  name                                        = var.ai.text.analytics.name
  resource_group_name                         = azurerm_resource_group.ai.name
  location                                    = azurerm_resource_group.ai.location
  sku_name                                    = var.ai.text.analytics.tier
  custom_subdomain_name                       = var.ai.text.analytics.domainName != "" ? var.ai.text.analytics.domainName : var.ai.text.analytics.name
  custom_question_answering_search_service_id = module.global.search.enable ? data.azurerm_search_service.studio[0].id : null
  kind                                        = "TextAnalytics"
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
    identity_client_id = data.azurerm_user_assigned_identity.studio.client_id
    storage_account_id = data.azurerm_storage_account.studio.id
  }
}

resource azurerm_private_endpoint ai_text_analytics {
  for_each = {
    for subnet in local.virtualNetworksSubnetCompute : subnet.key => subnet
  }
  name                = "${lower(each.value.virtualNetworkName)}-ai-text-analytics"
  resource_group_name = each.value.resourceGroupName
  location            = each.value.regionName
  subnet_id           = "${each.value.virtualNetworkId}/subnets/${each.value.name}"
  private_service_connection {
    name                           = azurerm_cognitive_account.ai_text_analytics.name
    private_connection_resource_id = azurerm_cognitive_account.ai_text_analytics.id
    is_manual_connection           = false
    subresource_names = [
      "account"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.ai[each.value.virtualNetworkName].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.ai.id
    ]
  }
}

################################################################################################
# AI Translator (https://learn.microsoft.com/azure/ai-services/translator/translator-overview) #
################################################################################################

resource azurerm_cognitive_account ai_text_translator {
  name                  = var.ai.text.translator.name
  resource_group_name   = azurerm_resource_group.ai.name
  location              = azurerm_resource_group.ai.location
  sku_name              = var.ai.text.translator.tier
  custom_subdomain_name = var.ai.text.translator.domainName != "" ? var.ai.text.translator.domainName : var.ai.text.translator.name
  kind                  = "TextTranslation"
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
}

resource azurerm_private_endpoint ai_text_translator {
  for_each = {
    for subnet in local.virtualNetworksSubnetCompute : subnet.key => subnet
  }
  name                = "${lower(each.value.virtualNetworkName)}-ai-text-translator"
  resource_group_name = each.value.resourceGroupName
  location            = each.value.regionName
  subnet_id           = "${each.value.virtualNetworkId}/subnets/${each.value.name}"
  private_service_connection {
    name                           = azurerm_cognitive_account.ai_text_translator.name
    private_connection_resource_id = azurerm_cognitive_account.ai_text_translator.id
    is_manual_connection           = false
    subresource_names = [
      "account"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.ai[each.value.virtualNetworkName].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.ai.id
    ]
  }
}
