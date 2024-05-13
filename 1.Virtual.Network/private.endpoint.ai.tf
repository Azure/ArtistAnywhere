
locals {
  aiEnable                = try(data.terraform_remote_state.ai.outputs.ai.cognitive.enable, false) || try(data.terraform_remote_state.ai.outputs.ai.speech.enable, false) || try(data.terraform_remote_state.ai.outputs.ai.language.conversational.enable, false) || try(data.terraform_remote_state.ai.outputs.ai.language.textAnalytics.enable, false) || try(data.terraform_remote_state.ai.outputs.ai.language.textTranslation.enable, false) || try(data.terraform_remote_state.ai.outputs.ai.vision.enable, false) || try(data.terraform_remote_state.ai.outputs.ai.vision.training.enable, false) || try(data.terraform_remote_state.ai.outputs.ai.vision.prediction.enable, false) || try(data.terraform_remote_state.ai.outputs.ai.face.enable, false) || try(data.terraform_remote_state.ai.outputs.ai.document.enable, false) || try(data.terraform_remote_state.ai.outputs.ai.contentSafety.enable, false) || try(data.terraform_remote_state.ai.outputs.ai.immersiveReader.enable, false)
  aiOpenEnable            = try(data.terraform_remote_state.ai.outputs.ai.open.enable, false)
  aiSearchEnable          = try(data.terraform_remote_state.ai.outputs.ai.search.enable, false)
  aiMachineLearningEnable = try(data.terraform_remote_state.ai.outputs.ai.machineLearning.enable, false)
}

resource azurerm_private_dns_zone ai {
  count               = local.aiEnable ? 1 : 0
  name                = "privatelink.cognitiveservices.azure.com"
  resource_group_name = azurerm_resource_group.network.name
}

resource azurerm_private_dns_zone ai_open {
  count               = local.aiOpenEnable ? 1 : 0
  name                = "privatelink.openai.azure.com"
  resource_group_name = azurerm_resource_group.network.name
}

resource azurerm_private_dns_zone ai_search {
  count               = local.aiSearchEnable ? 1 : 0
  name                = "privatelink.search.windows.net"
  resource_group_name = azurerm_resource_group.network.name
}

resource azurerm_private_dns_zone ai_machine_learning {
  count               = local.aiMachineLearningEnable ? 1 : 0
  name                = "privatelink.api.azureml.ms"
  resource_group_name = azurerm_resource_group.network.name
}

resource azurerm_private_dns_zone_virtual_network_link ai {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.key => virtualNetwork if local.aiEnable
  }
  name                  = "${lower(each.value.key)}-ai"
  resource_group_name   = azurerm_private_dns_zone.ai[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.ai[0].name
  virtual_network_id    = each.value.id
}

resource azurerm_private_dns_zone_virtual_network_link ai_open {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.key => virtualNetwork if local.aiOpenEnable
  }
  name                  = "${lower(each.value.key)}-ai-open"
  resource_group_name   = azurerm_private_dns_zone.ai_open[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.ai_open[0].name
  virtual_network_id    = each.value.id
}

resource azurerm_private_dns_zone_virtual_network_link ai_search {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.key => virtualNetwork if local.aiSearchEnable
  }
  name                  = "${lower(each.value.key)}-ai-search"
  resource_group_name   = azurerm_private_dns_zone.ai_search[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.ai_search[0].name
  virtual_network_id    = each.value.id
}

resource azurerm_private_dns_zone_virtual_network_link ai_machine_learning {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.key => virtualNetwork if local.aiMachineLearningEnable
  }
  name                  = "${lower(each.value.key)}-ai-machine-learning"
  resource_group_name   = azurerm_private_dns_zone.ai_machine_learning[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.ai_machine_learning[0].name
  virtual_network_id    = each.value.id
}

resource azurerm_private_endpoint ai {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.key => virtualNetwork if try(data.terraform_remote_state.ai.outputs.ai.cognitive.enable, false)
  }
  name                = "${lower(each.value.key)}-ai"
  resource_group_name = each.value.resourceGroupName
  location            = each.value.regionName
  subnet_id           = "${each.value.id}/subnets/AI"
  private_service_connection {
    name                           = data.terraform_remote_state.ai.outputs.ai.cognitive.name
    private_connection_resource_id = data.terraform_remote_state.ai.outputs.ai.cognitive.id
    is_manual_connection           = false
    subresource_names = [
      "account"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.ai[each.value.key].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.ai[0].id
    ]
  }
}

resource azurerm_private_endpoint ai_open {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.key => virtualNetwork if local.aiOpenEnable
  }
  name                = "${lower(each.value.key)}-ai-open"
  resource_group_name = each.value.resourceGroupName
  location            = each.value.regionName
  subnet_id           = "${each.value.id}/subnets/AI"
  private_service_connection {
    name                           = data.terraform_remote_state.ai.outputs.ai.open.name
    private_connection_resource_id = data.terraform_remote_state.ai.outputs.ai.open.id
    is_manual_connection           = false
    subresource_names = [
      "account"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.ai_open[each.value.key].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.ai_open[0].id
    ]
  }
}

resource azurerm_private_endpoint ai_vision {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.key => virtualNetwork if try(data.terraform_remote_state.ai.outputs.ai.vision.enable, false)
  }
  name                = "${lower(each.value.key)}-ai-vision"
  resource_group_name = each.value.resourceGroupName
  location            = each.value.regionName
  subnet_id           = "${each.value.id}/subnets/AI"
  private_service_connection {
    name                           = data.terraform_remote_state.ai.outputs.ai.vision.name
    private_connection_resource_id = data.terraform_remote_state.ai.outputs.ai.vision.id
    is_manual_connection           = false
    subresource_names = [
      "account"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.ai[each.value.key].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.ai[0].id
    ]
  }
}

resource azurerm_private_endpoint ai_vision_training {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.key => virtualNetwork if try(data.terraform_remote_state.ai.outputs.ai.vision.training.enable, false)
  }
  name                = "${lower(each.value.key)}-ai-vision-training"
  resource_group_name = each.value.resourceGroupName
  location            = each.value.regionName
  subnet_id           = "${each.value.id}/subnets/AI"
  private_service_connection {
    name                           = data.terraform_remote_state.ai.outputs.ai.vision.training.name
    private_connection_resource_id = data.terraform_remote_state.ai.outputs.ai.vision.training.id
    is_manual_connection           = false
    subresource_names = [
      "account"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.ai[each.value.key].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.ai[0].id
    ]
  }
}

resource azurerm_private_endpoint ai_vision_prediction {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.key => virtualNetwork if try(data.terraform_remote_state.ai.outputs.ai.vision.prediction.enable, false)
  }
  name                = "${lower(each.value.key)}-ai-vision-prediction"
  resource_group_name = each.value.resourceGroupName
  location            = each.value.regionName
  subnet_id           = "${each.value.id}/subnets/AI"
  private_service_connection {
    name                           = data.terraform_remote_state.ai.outputs.ai.vision.prediction.name
    private_connection_resource_id = data.terraform_remote_state.ai.outputs.ai.vision.prediction.id
    is_manual_connection           = false
    subresource_names = [
      "account"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.ai[each.value.key].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.ai[0].id
    ]
  }
}

resource azurerm_private_endpoint ai_face {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.key => virtualNetwork if try(data.terraform_remote_state.ai.outputs.ai.face.enable, false)
  }
  name                = "${lower(each.value.key)}-ai-face"
  resource_group_name = each.value.resourceGroupName
  location            = each.value.regionName
  subnet_id           = "${each.value.id}/subnets/AI"
  private_service_connection {
    name                           = data.terraform_remote_state.ai.outputs.ai.face.name
    private_connection_resource_id = data.terraform_remote_state.ai.outputs.ai.face.id
    is_manual_connection           = false
    subresource_names = [
      "account"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.ai[each.value.key].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.ai[0].id
    ]
  }
}

resource azurerm_private_endpoint ai_speech {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.key => virtualNetwork if try(data.terraform_remote_state.ai.outputs.ai.speech.enable, false)
  }
  name                = "${lower(each.value.key)}-ai-speech"
  resource_group_name = each.value.resourceGroupName
  location            = each.value.regionName
  subnet_id           = "${each.value.id}/subnets/AI"
  private_service_connection {
    name                           = data.terraform_remote_state.ai.outputs.ai.speech.name
    private_connection_resource_id = data.terraform_remote_state.ai.outputs.ai.speech.id
    is_manual_connection           = false
    subresource_names = [
      "account"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.ai[each.value.key].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.ai[0].id
    ]
  }
}

resource azurerm_private_endpoint ai_language_conversational {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.key => virtualNetwork if try(data.terraform_remote_state.ai.outputs.ai.language.conversational.enable, false)
  }
  name                = "${lower(each.value.key)}-ai-language-conversational"
  resource_group_name = each.value.resourceGroupName
  location            = each.value.regionName
  subnet_id           = "${each.value.id}/subnets/AI"
  private_service_connection {
    name                           = data.terraform_remote_state.ai.outputs.ai.language.conversational.name
    private_connection_resource_id = data.terraform_remote_state.ai.outputs.ai.language.conversational.id
    is_manual_connection           = false
    subresource_names = [
      "account"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.ai[each.value.key].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.ai[0].id
    ]
  }
}

resource azurerm_private_endpoint ai_text_analytics {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.key => virtualNetwork if try(data.terraform_remote_state.ai.outputs.ai.language.textAnalytics.enable, false)
  }
  name                = "${lower(each.value.key)}-ai-text-analytics"
  resource_group_name = each.value.resourceGroupName
  location            = each.value.regionName
  subnet_id           = "${each.value.id}/subnets/AI"
  private_service_connection {
    name                           = data.terraform_remote_state.ai.outputs.ai.language.textAnalytics.name
    private_connection_resource_id = data.terraform_remote_state.ai.outputs.ai.language.textAnalytics.id
    is_manual_connection           = false
    subresource_names = [
      "account"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.ai[each.value.key].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.ai[0].id
    ]
  }
}

resource azurerm_private_endpoint ai_text_translation {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.key => virtualNetwork if try(data.terraform_remote_state.ai.outputs.ai.language.textTranslation.enable, false)
  }
  name                = "${lower(each.value.key)}-ai-text-translation"
  resource_group_name = each.value.resourceGroupName
  location            = each.value.regionName
  subnet_id           = "${each.value.id}/subnets/AI"
  private_service_connection {
    name                           = data.terraform_remote_state.ai.outputs.ai.language.textTranslation.name
    private_connection_resource_id = data.terraform_remote_state.ai.outputs.ai.language.textTranslation.id
    is_manual_connection           = false
    subresource_names = [
      "account"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.ai[each.value.key].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.ai[0].id
    ]
  }
}

resource azurerm_private_endpoint ai_document {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.key => virtualNetwork if try(data.terraform_remote_state.ai.outputs.ai.document.enable, false)
  }
  name                = "${lower(each.value.key)}-ai-document"
  resource_group_name = each.value.resourceGroupName
  location            = each.value.regionName
  subnet_id           = "${each.value.id}/subnets/AI"
  private_service_connection {
    name                           = data.terraform_remote_state.ai.outputs.ai.document.name
    private_connection_resource_id = data.terraform_remote_state.ai.outputs.ai.document.id
    is_manual_connection           = false
    subresource_names = [
      "account"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.ai[each.value.key].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.ai[0].id
    ]
  }
}

resource azurerm_private_endpoint ai_search {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.key => virtualNetwork if local.aiSearchEnable
  }
  name                = "${lower(each.value.key)}-ai-search"
  resource_group_name = each.value.resourceGroupName
  location            = each.value.regionName
  subnet_id           = "${each.value.id}/subnets/AI"
  private_service_connection {
    name                           = data.terraform_remote_state.ai.outputs.ai.search.name
    private_connection_resource_id = data.terraform_remote_state.ai.outputs.ai.search.id
    is_manual_connection           = false
    subresource_names = [
      "searchService"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.ai_search[each.value.key].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.ai_search[0].id
    ]
  }
}

resource azurerm_private_endpoint ai_machine_learning {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.key => virtualNetwork if local.aiMachineLearningEnable
  }
  name                = "${lower(each.value.key)}-ai-machine-learning"
  resource_group_name = each.value.resourceGroupName
  location            = each.value.regionName
  subnet_id           = "${each.value.id}/subnets/AI"
  private_service_connection {
    name                           = data.terraform_remote_state.ai.outputs.ai.machineLearning.name
    private_connection_resource_id = data.terraform_remote_state.ai.outputs.ai.machineLearning.id
    is_manual_connection           = false
    subresource_names = [
      "amlworkspace"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.ai_machine_learning[each.value.key].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.ai_machine_learning[0].id
    ]
  }
}
