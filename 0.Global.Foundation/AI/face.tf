#############################################################################################
# AI Face (https://learn.microsoft.com/azure/ai-services/computer-vision/overview-identity) #
#############################################################################################

resource azurerm_cognitive_account ai_face {
  count                 = var.ai.face.enable ? 1 : 0
  name                  = var.ai.face.name
  resource_group_name   = azurerm_resource_group.ai.name
  location              = azurerm_resource_group.ai.location
  sku_name              = var.ai.face.tier
  custom_subdomain_name = var.ai.face.domainName != "" ? var.ai.face.domainName : var.ai.face.name
  kind                  = "Face"
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
    for_each = var.ai.encryption.enable ? [1] : []
    content {
      key_vault_key_id = data.azurerm_key_vault_key.data_encryption.id
    }
  }
}
