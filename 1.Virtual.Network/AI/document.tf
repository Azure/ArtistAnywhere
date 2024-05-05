###########################################################################################################
# AI Document Intelligence (https://learn.microsoft.com/azure/ai-services/document-intelligence/overview) #
###########################################################################################################

resource azurerm_cognitive_account ai_document {
  count                 = var.ai.document.enable ? 1 : 0
  name                  = var.ai.document.name
  resource_group_name   = azurerm_resource_group.ai.name
  location              = azurerm_resource_group.ai.location
  sku_name              = var.ai.document.tier
  custom_subdomain_name = var.ai.document.domainName != "" ? var.ai.document.domainName : var.ai.document.name
  kind                  = "FormRecognizer"
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

resource azurerm_private_endpoint ai_document {
  for_each = {
    for subnet in local.virtualNetworksSubnetCompute : subnet.key => subnet if var.ai.document.enable && subnet.virtualNetworkEdgeZone == ""
  }
  name                = "${lower(each.value.virtualNetworkName)}-ai-document"
  resource_group_name = each.value.resourceGroupName
  location            = each.value.regionName
  subnet_id           = "${each.value.virtualNetworkId}/subnets/${each.value.name}"
  private_service_connection {
    name                           = azurerm_cognitive_account.ai_document[0].name
    private_connection_resource_id = azurerm_cognitive_account.ai_document[0].id
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
