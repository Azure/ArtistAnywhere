
locals {
  aiEnable                = try(data.terraform_remote_state.ai[0].outputs.ai.cognitive.enable, false) || try(data.terraform_remote_state.ai[0].outputs.ai.speech.enable, false) || try(data.terraform_remote_state.ai[0].outputs.ai.language.conversational.enable, false) || try(data.terraform_remote_state.ai[0].outputs.ai.language.textAnalytics.enable, false) || try(data.terraform_remote_state.ai[0].outputs.ai.language.textTranslation.enable, false) || try(data.terraform_remote_state.ai[0].outputs.ai.vision.enable, false) || try(data.terraform_remote_state.ai[0].outputs.ai.vision.training.enable, false) || try(data.terraform_remote_state.ai[0].outputs.ai.vision.prediction.enable, false) || try(data.terraform_remote_state.ai[0].outputs.ai.face.enable, false) || try(data.terraform_remote_state.ai[0].outputs.ai.document.enable, false) || try(data.terraform_remote_state.ai[0].outputs.ai.contentSafety.enable, false) || try(data.terraform_remote_state.ai[0].outputs.ai.immersiveReader.enable, false)
  aiOpenEnable            = try(data.terraform_remote_state.ai[0].outputs.ai.open.enable, false)
  aiSearchEnable          = try(data.terraform_remote_state.ai[0].outputs.ai.search.enable, false)
  aiMachineLearningEnable = try(data.terraform_remote_state.ai[0].outputs.ai.machineLearning.enable, false)
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

resource azurerm_private_dns_zone ai_machine_learning_notebook {
  count               = local.aiMachineLearningEnable ? 1 : 0
  name                = "privatelink.notebooks.azure.net"
  resource_group_name = azurerm_resource_group.network.name
}

resource azurerm_private_dns_zone_virtual_network_link ai {
  count                 = local.aiEnable ? 1 : 0
  name                  = "ai"
  resource_group_name   = azurerm_private_dns_zone.ai[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.ai[0].name
  virtual_network_id    = local.virtualNetwork.id
}

resource azurerm_private_dns_zone_virtual_network_link ai_open {
  count                 = local.aiOpenEnable ? 1 : 0
  name                  = "ai-open"
  resource_group_name   = azurerm_private_dns_zone.ai_open[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.ai_open[0].name
  virtual_network_id    = local.virtualNetwork.id
}

resource azurerm_private_dns_zone_virtual_network_link ai_search {
  count                 = local.aiSearchEnable ? 1 : 0
  name                  = "ai-search"
  resource_group_name   = azurerm_private_dns_zone.ai_search[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.ai_search[0].name
  virtual_network_id    = local.virtualNetwork.id
}

resource azurerm_private_dns_zone_virtual_network_link ai_machine_learning {
  count                 = local.aiMachineLearningEnable ? 1 : 0
  name                  = "ai-machine-learning"
  resource_group_name   = azurerm_private_dns_zone.ai_machine_learning[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.ai_machine_learning[0].name
  virtual_network_id    = local.virtualNetwork.id
}

resource azurerm_private_dns_zone_virtual_network_link ai_machine_learning_notebook {
  count                 = local.aiMachineLearningEnable ? 1 : 0
  name                  = "ai-machine-learning-notebook"
  resource_group_name   = azurerm_private_dns_zone.ai_machine_learning_notebook[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.ai_machine_learning_notebook[0].name
  virtual_network_id    = local.virtualNetwork.id
}

resource azurerm_private_endpoint ai {
  count               = try(data.terraform_remote_state.ai[0].outputs.ai.cognitive.enable, false) ? 1 : 0
  name                = lower(data.terraform_remote_state.ai[0].outputs.ai.cognitive.name)
  resource_group_name = data.terraform_remote_state.ai[0].outputs.ai.resourceGroupName
  location            = data.terraform_remote_state.ai[0].outputs.ai.regionName
  subnet_id           = "${local.virtualNetwork.id}/subnets/AI"
  private_service_connection {
    name                           = data.terraform_remote_state.ai[0].outputs.ai.cognitive.name
    private_connection_resource_id = data.terraform_remote_state.ai[0].outputs.ai.cognitive.id
    is_manual_connection           = false
    subresource_names = [
      "account"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.ai[0].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.ai[0].id
    ]
  }
}

resource azurerm_private_endpoint ai_open {
  count               = local.aiOpenEnable ? 1 : 0
  name                = lower(data.terraform_remote_state.ai[0].outputs.ai.open.name)
  resource_group_name = data.terraform_remote_state.ai[0].outputs.ai.resourceGroupName
  location            = data.terraform_remote_state.ai[0].outputs.ai.regionName
  subnet_id           = "${local.virtualNetwork.id}/subnets/AI"
  private_service_connection {
    name                           = data.terraform_remote_state.ai[0].outputs.ai.open.name
    private_connection_resource_id = data.terraform_remote_state.ai[0].outputs.ai.open.id
    is_manual_connection           = false
    subresource_names = [
      "account"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.ai_open[0].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.ai_open[0].id
    ]
  }
}

resource azurerm_private_endpoint ai_vision {
  count               = try(data.terraform_remote_state.ai[0].outputs.ai.vision.enable, false) ? 1 : 0
  name                = lower(data.terraform_remote_state.ai[0].outputs.ai.vision.name)
  resource_group_name = data.terraform_remote_state.ai[0].outputs.ai.resourceGroupName
  location            = data.terraform_remote_state.ai[0].outputs.ai.regionName
  subnet_id           = "${local.virtualNetwork.id}/subnets/AI"
  private_service_connection {
    name                           = data.terraform_remote_state.ai[0].outputs.ai.vision.name
    private_connection_resource_id = data.terraform_remote_state.ai[0].outputs.ai.vision.id
    is_manual_connection           = false
    subresource_names = [
      "account"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.ai[0].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.ai[0].id
    ]
  }
}

resource azurerm_private_endpoint ai_vision_training {
  count               = try(data.terraform_remote_state.ai[0].outputs.ai.vision.training.enable, false) ? 1 : 0
  name                = lower(data.terraform_remote_state.ai[0].outputs.ai.vision.training.name)
  resource_group_name = data.terraform_remote_state.ai[0].outputs.ai.resourceGroupName
  location            = data.terraform_remote_state.ai[0].outputs.ai.regionName
  subnet_id           = "${local.virtualNetwork.id}/subnets/AI"
  private_service_connection {
    name                           = data.terraform_remote_state.ai[0].outputs.ai.vision.training.name
    private_connection_resource_id = data.terraform_remote_state.ai[0].outputs.ai.vision.training.id
    is_manual_connection           = false
    subresource_names = [
      "account"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.ai[0].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.ai[0].id
    ]
  }
}

resource azurerm_private_endpoint ai_vision_prediction {
  count               = try(data.terraform_remote_state.ai[0].outputs.ai.vision.prediction.enable, false) ? 1 : 0
  name                = lower(data.terraform_remote_state.ai[0].outputs.ai.vision.prediction.name)
  resource_group_name = data.terraform_remote_state.ai[0].outputs.ai.resourceGroupName
  location            = data.terraform_remote_state.ai[0].outputs.ai.regionName
  subnet_id           = "${local.virtualNetwork.id}/subnets/AI"
  private_service_connection {
    name                           = data.terraform_remote_state.ai[0].outputs.ai.vision.prediction.name
    private_connection_resource_id = data.terraform_remote_state.ai[0].outputs.ai.vision.prediction.id
    is_manual_connection           = false
    subresource_names = [
      "account"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.ai[0].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.ai[0].id
    ]
  }
}

resource azurerm_private_endpoint ai_face {
  count               = try(data.terraform_remote_state.ai[0].outputs.ai.face.enable, false) ? 1 : 0
  name                = lower(data.terraform_remote_state.ai[0].outputs.ai.face.name)
  resource_group_name = data.terraform_remote_state.ai[0].outputs.ai.resourceGroupName
  location            = data.terraform_remote_state.ai[0].outputs.ai.regionName
  subnet_id           = "${local.virtualNetwork.id}/subnets/AI"
  private_service_connection {
    name                           = data.terraform_remote_state.ai[0].outputs.ai.face.name
    private_connection_resource_id = data.terraform_remote_state.ai[0].outputs.ai.face.id
    is_manual_connection           = false
    subresource_names = [
      "account"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.ai[0].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.ai[0].id
    ]
  }
}

resource azurerm_private_endpoint ai_speech {
  count               = try(data.terraform_remote_state.ai[0].outputs.ai.speech.enable, false) ? 1 : 0
  name                = lower(data.terraform_remote_state.ai[0].outputs.ai.speech.name)
  resource_group_name = data.terraform_remote_state.ai[0].outputs.ai.resourceGroupName
  location            = data.terraform_remote_state.ai[0].outputs.ai.regionName
  subnet_id           = "${local.virtualNetwork.id}/subnets/AI"
  private_service_connection {
    name                           = data.terraform_remote_state.ai[0].outputs.ai.speech.name
    private_connection_resource_id = data.terraform_remote_state.ai[0].outputs.ai.speech.id
    is_manual_connection           = false
    subresource_names = [
      "account"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.ai[0].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.ai[0].id
    ]
  }
}

resource azurerm_private_endpoint ai_language_conversational {
  count               = try(data.terraform_remote_state.ai[0].outputs.ai.language.conversational.enable, false) ? 1 : 0
  name                = lower(data.terraform_remote_state.ai[0].outputs.ai.language.conversational.name)
  resource_group_name = data.terraform_remote_state.ai[0].outputs.ai.resourceGroupName
  location            = data.terraform_remote_state.ai[0].outputs.ai.regionName
  subnet_id           = "${local.virtualNetwork.id}/subnets/AI"
  private_service_connection {
    name                           = data.terraform_remote_state.ai[0].outputs.ai.language.conversational.name
    private_connection_resource_id = data.terraform_remote_state.ai[0].outputs.ai.language.conversational.id
    is_manual_connection           = false
    subresource_names = [
      "account"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.ai[0].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.ai[0].id
    ]
  }
}

resource azurerm_private_endpoint ai_language_text_analytics {
  count               = try(data.terraform_remote_state.ai[0].outputs.ai.language.textAnalytics.enable, false) ? 1 : 0
  name                = lower(data.terraform_remote_state.ai[0].outputs.ai.language.textAnalytics.name)
  resource_group_name = data.terraform_remote_state.ai[0].outputs.ai.resourceGroupName
  location            = data.terraform_remote_state.ai[0].outputs.ai.regionName
  subnet_id           = "${local.virtualNetwork.id}/subnets/AI"
  private_service_connection {
    name                           = data.terraform_remote_state.ai[0].outputs.ai.language.textAnalytics.name
    private_connection_resource_id = data.terraform_remote_state.ai[0].outputs.ai.language.textAnalytics.id
    is_manual_connection           = false
    subresource_names = [
      "account"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.ai[0].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.ai[0].id
    ]
  }
}

resource azurerm_private_endpoint ai_language_text_translation {
  count               = try(data.terraform_remote_state.ai[0].outputs.ai.language.textTranslation.enable, false) ? 1 : 0
  name                = lower(data.terraform_remote_state.ai[0].outputs.ai.language.textTranslation.name)
  resource_group_name = data.terraform_remote_state.ai[0].outputs.ai.resourceGroupName
  location            = data.terraform_remote_state.ai[0].outputs.ai.regionName
  subnet_id           = "${local.virtualNetwork.id}/subnets/AI"
  private_service_connection {
    name                           = data.terraform_remote_state.ai[0].outputs.ai.language.textTranslation.name
    private_connection_resource_id = data.terraform_remote_state.ai[0].outputs.ai.language.textTranslation.id
    is_manual_connection           = false
    subresource_names = [
      "account"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.ai[0].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.ai[0].id
    ]
  }
}

resource azurerm_private_endpoint ai_document {
  count               = try(data.terraform_remote_state.ai[0].outputs.ai.document.enable, false) ? 1 : 0
  name                = lower(data.terraform_remote_state.ai[0].outputs.ai.document.name)
  resource_group_name = data.terraform_remote_state.ai[0].outputs.ai.resourceGroupName
  location            = data.terraform_remote_state.ai[0].outputs.ai.regionName
  subnet_id           = "${local.virtualNetwork.id}/subnets/AI"
  private_service_connection {
    name                           = data.terraform_remote_state.ai[0].outputs.ai.document.name
    private_connection_resource_id = data.terraform_remote_state.ai[0].outputs.ai.document.id
    is_manual_connection           = false
    subresource_names = [
      "account"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.ai[0].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.ai[0].id
    ]
  }
}

resource azurerm_private_endpoint ai_search {
  count               = local.aiSearchEnable ? 1 : 0
  name                = lower(data.terraform_remote_state.ai[0].outputs.ai.search.name)
  resource_group_name = data.terraform_remote_state.ai[0].outputs.ai.resourceGroupName
  location            = data.terraform_remote_state.ai[0].outputs.ai.regionName
  subnet_id           = "${local.virtualNetwork.id}/subnets/AI"
  private_service_connection {
    name                           = data.terraform_remote_state.ai[0].outputs.ai.search.name
    private_connection_resource_id = data.terraform_remote_state.ai[0].outputs.ai.search.id
    is_manual_connection           = false
    subresource_names = [
      "searchService"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.ai_search[0].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.ai_search[0].id
    ]
  }
}

resource azurerm_private_endpoint ai_content_safety {
  count               = try(data.terraform_remote_state.ai[0].outputs.ai.contentSafety.enable, false) ? 1 : 0
  name                = lower(data.terraform_remote_state.ai[0].outputs.ai.contentSafety.name)
  resource_group_name = data.terraform_remote_state.ai[0].outputs.ai.resourceGroupName
  location            = data.terraform_remote_state.ai[0].outputs.ai.regionName
  subnet_id           = "${local.virtualNetwork.id}/subnets/AI"
  private_service_connection {
    name                           = data.terraform_remote_state.ai[0].outputs.ai.contentSafety.name
    private_connection_resource_id = data.terraform_remote_state.ai[0].outputs.ai.contentSafety.id
    is_manual_connection           = false
    subresource_names = [
      "account"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.ai[0].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.ai[0].id
    ]
  }
}

resource azurerm_private_endpoint ai_immersive_reader {
  count               = try(data.terraform_remote_state.ai[0].outputs.ai.immersiveReader.enable, false) ? 1 : 0
  name                = lower(data.terraform_remote_state.ai[0].outputs.ai.immersiveReader.name)
  resource_group_name = data.terraform_remote_state.ai[0].outputs.ai.resourceGroupName
  location            = data.terraform_remote_state.ai[0].outputs.ai.regionName
  subnet_id           = "${local.virtualNetwork.id}/subnets/AI"
  private_service_connection {
    name                           = data.terraform_remote_state.ai[0].outputs.ai.immersiveReader.name
    private_connection_resource_id = data.terraform_remote_state.ai[0].outputs.ai.immersiveReader.id
    is_manual_connection           = false
    subresource_names = [
      "account"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.ai[0].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.ai[0].id
    ]
  }
}

resource azurerm_private_endpoint ai_machine_learning {
  count               = local.aiMachineLearningEnable ? 1 : 0
  name                = lower(data.terraform_remote_state.ai[0].outputs.ai.machineLearning.name)
  resource_group_name = data.terraform_remote_state.ai[0].outputs.ai.resourceGroupName
  location            = data.terraform_remote_state.ai[0].outputs.ai.regionName
  subnet_id           = "${local.virtualNetwork.id}/subnets/AI"
  private_service_connection {
    name                           = data.terraform_remote_state.ai[0].outputs.ai.machineLearning.name
    private_connection_resource_id = data.terraform_remote_state.ai[0].outputs.ai.machineLearning.id
    is_manual_connection           = false
    subresource_names = [
      "amlworkspace"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.ai_machine_learning[0].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.ai_machine_learning[0].id
    ]
  }
}
