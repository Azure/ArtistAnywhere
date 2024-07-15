###############################################################################################
# AI Computer Vision (https://learn.microsoft.com/azure/ai-services/computer-vision/overview) #
###############################################################################################

resource azurerm_cognitive_account ai_vision {
  count                 = var.ai.vision.enable ? 1 : 0
  name                  = var.ai.vision.name
  resource_group_name   = azurerm_resource_group.ai.name
  location              = azurerm_resource_group.ai.location
  sku_name              = var.ai.vision.tier
  custom_subdomain_name = var.ai.vision.domainName != "" ? var.ai.vision.domainName : var.ai.vision.name
  kind                  = "ComputerVision"
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

###################################################################################################
# AI Custom Vision (https://learn.microsoft.com/azure/ai-services/custom-vision-service/overview) #
###################################################################################################

resource azurerm_cognitive_account ai_vision_training {
  count                 = var.ai.vision.training.enable ? 1 : 0
  name                  = var.ai.vision.training.name
  resource_group_name   = azurerm_resource_group.ai.name
  location              = azurerm_resource_group.ai.location
  sku_name              = var.ai.vision.training.tier
  custom_subdomain_name = var.ai.vision.training.domainName != "" ? var.ai.vision.training.domainName : var.ai.vision.training.name
  kind                  = "CustomVision.Training"
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

resource azurerm_cognitive_account ai_vision_prediction {
  count                 = var.ai.vision.prediction.enable ? 1 : 0
  name                  = var.ai.vision.prediction.name
  resource_group_name   = azurerm_resource_group.ai.name
  location              = azurerm_resource_group.ai.location
  sku_name              = var.ai.vision.prediction.tier
  custom_subdomain_name = var.ai.vision.prediction.domainName != "" ? var.ai.vision.prediction.domainName : var.ai.vision.prediction.name
  kind                  = "CustomVision.Prediction"
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
