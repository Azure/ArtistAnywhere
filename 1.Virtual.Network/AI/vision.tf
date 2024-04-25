###############################################################################################
# AI Computer Vision (https://learn.microsoft.com/azure/ai-services/computer-vision/overview) #
###############################################################################################

resource azurerm_cognitive_account ai_vision {
  name                  = var.ai.vision.name
  resource_group_name   = azurerm_resource_group.ai.name
  location              = azurerm_resource_group.ai.location
  sku_name              = var.ai.vision.tier
  custom_subdomain_name = var.ai.vision.domainName != "" ? var.ai.vision.domainName : var.ai.vision.name
  kind                  = "ComputerVision"
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
      identity_client_id = data.azurerm_user_assigned_identity.studio.client_id
      key_vault_key_id   = data.azurerm_key_vault_key.data_encryption[0].id
    }
  }
}

resource azurerm_private_endpoint ai_vision {
  for_each = {
    for subnet in local.virtualNetworksSubnetCompute : subnet.key => subnet if subnet.virtualNetworkEdgeZone == ""
  }
  name                = "${lower(each.value.virtualNetworkName)}-ai-vision"
  resource_group_name = each.value.resourceGroupName
  location            = each.value.regionName
  subnet_id           = "${each.value.virtualNetworkId}/subnets/${each.value.name}"
  private_service_connection {
    name                           = azurerm_cognitive_account.ai_vision.name
    private_connection_resource_id = azurerm_cognitive_account.ai_vision.id
    is_manual_connection           = false
    subresource_names = [
      "account"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.ai[each.value.virtualNetworkKey].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.ai.id
    ]
  }
}

###################################################################################################
# AI Custom Vision (https://learn.microsoft.com/azure/ai-services/custom-vision-service/overview) #
###################################################################################################

resource azurerm_cognitive_account ai_vision_training {
  name                  = var.ai.vision.custom.training.name
  resource_group_name   = azurerm_resource_group.ai.name
  location              = var.ai.vision.custom.training.regionName != "" ? var.ai.vision.custom.training.regionName : azurerm_resource_group.ai.location
  sku_name              = var.ai.vision.custom.training.tier
  custom_subdomain_name = var.ai.vision.custom.training.domainName != "" ? var.ai.vision.custom.training.domainName : var.ai.vision.custom.training.name
  kind                  = "CustomVision.Training"
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
      identity_client_id = data.azurerm_user_assigned_identity.studio.client_id
      key_vault_key_id   = data.azurerm_key_vault_key.data_encryption[0].id
    }
  }
}

resource azurerm_private_endpoint ai_vision_training {
  for_each = {
    for subnet in local.virtualNetworksSubnetCompute : subnet.key => subnet if subnet.virtualNetworkEdgeZone == ""
  }
  name                = "${lower(each.value.virtualNetworkName)}-ai-vision-training"
  resource_group_name = each.value.resourceGroupName
  location            = each.value.regionName
  subnet_id           = "${each.value.virtualNetworkId}/subnets/${each.value.name}"
  private_service_connection {
    name                           = azurerm_cognitive_account.ai_vision_training.name
    private_connection_resource_id = azurerm_cognitive_account.ai_vision_training.id
    is_manual_connection           = false
    subresource_names = [
      "account"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.ai[each.value.virtualNetworkKey].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.ai.id
    ]
  }
}

resource azurerm_cognitive_account ai_vision_prediction {
  name                  = var.ai.vision.custom.prediction.name
  resource_group_name   = azurerm_resource_group.ai.name
  location              = var.ai.vision.custom.prediction.regionName != "" ? var.ai.vision.custom.prediction.regionName : azurerm_resource_group.ai.location
  sku_name              = var.ai.vision.custom.prediction.tier
  custom_subdomain_name = var.ai.vision.custom.prediction.domainName != "" ? var.ai.vision.custom.prediction.domainName : var.ai.vision.custom.prediction.name
  kind                  = "CustomVision.Prediction"
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
      identity_client_id = data.azurerm_user_assigned_identity.studio.client_id
      key_vault_key_id   = data.azurerm_key_vault_key.data_encryption[0].id
    }
  }
}

resource azurerm_private_endpoint ai_vision_prediction {
  for_each = {
    for subnet in local.virtualNetworksSubnetCompute : subnet.key => subnet if subnet.virtualNetworkEdgeZone == ""
  }
  name                = "${lower(each.value.virtualNetworkName)}-ai-vision-prediction"
  resource_group_name = each.value.resourceGroupName
  location            = each.value.regionName
  subnet_id           = "${each.value.virtualNetworkId}/subnets/${each.value.name}"
  private_service_connection {
    name                           = azurerm_cognitive_account.ai_vision_prediction.name
    private_connection_resource_id = azurerm_cognitive_account.ai_vision_prediction.id
    is_manual_connection           = false
    subresource_names = [
      "account"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.ai[each.value.virtualNetworkKey].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.ai.id
    ]
  }
}
