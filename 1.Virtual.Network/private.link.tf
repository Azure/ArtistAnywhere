#######################################################################################
# Private Link (https://learn.microsoft.com/azure/private-link/private-link-overview) #
#######################################################################################

resource azurerm_private_dns_zone storage_blob {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.network.name
}

resource azurerm_private_dns_zone storage_file {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = azurerm_resource_group.network.name
}

resource azurerm_private_dns_zone key_vault {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.network.name
}

resource azurerm_private_dns_zone event_grid {
  name                = "privatelink.eventgrid.azure.net"
  resource_group_name = azurerm_resource_group.network.name
}

resource azurerm_private_dns_zone app_config {
  name                = "privatelink.azconfig.io"
  resource_group_name = azurerm_resource_group.network.name
}

resource azurerm_private_dns_zone container_registry {
  count               = data.terraform_remote_state.global.outputs.containerRegistry.enable ? 1 : 0
  name                = "privatelink.azurecr.io"
  resource_group_name = data.terraform_remote_state.global.outputs.containerRegistry.resourceGroupName
}

resource azurerm_private_dns_zone ai_services_open {
  count               = data.terraform_remote_state.global.outputs.ai.services.enable ? 1 : 0
  name                = "privatelink.openai.azure.com"
  resource_group_name = data.terraform_remote_state.global.outputs.ai.resourceGroupName
}

resource azurerm_private_dns_zone ai_services_cognitive {
  count               = data.terraform_remote_state.global.outputs.ai.services.enable ? 1 : 0
  name                = "privatelink.cognitiveservices.azure.com"
  resource_group_name = data.terraform_remote_state.global.outputs.ai.resourceGroupName
}

resource azurerm_private_dns_zone ai_search {
  count               = data.terraform_remote_state.global.outputs.ai.search.enable ? 1 : 0
  name                = "privatelink.search.windows.net"
  resource_group_name = data.terraform_remote_state.global.outputs.ai.resourceGroupName
}

resource azurerm_private_dns_zone ai_machine_learning {
  count               = data.terraform_remote_state.global.outputs.ai.machineLearning.enable ? 1 : 0
  name                = "privatelink.api.azureml.ms"
  resource_group_name = data.terraform_remote_state.global.outputs.ai.machineLearning.resourceGroup.name
}

resource azurerm_private_dns_zone ai_machine_learning_notebook {
  count               = data.terraform_remote_state.global.outputs.ai.machineLearning.enable ? 1 : 0
  name                = "privatelink.notebooks.azure.net"
  resource_group_name = data.terraform_remote_state.global.outputs.ai.machineLearning.resourceGroup.name
}

resource azurerm_private_dns_zone_virtual_network_link storage_blob {
  name                  = "storage-blob"
  resource_group_name   = azurerm_private_dns_zone.storage_blob.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.storage_blob.name
  virtual_network_id    = local.virtualNetwork.id
  depends_on = [
    azurerm_virtual_network.studio
  ]
}

resource azurerm_private_dns_zone_virtual_network_link storage_file {
  name                  = "storage-file"
  resource_group_name   = azurerm_private_dns_zone.storage_file.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.storage_file.name
  virtual_network_id    = local.virtualNetwork.id
  depends_on = [
    azurerm_virtual_network.studio
  ]
}

resource azurerm_private_dns_zone_virtual_network_link key_vault {
  name                  = "key-vault"
  resource_group_name   = azurerm_private_dns_zone.key_vault.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.key_vault.name
  virtual_network_id    = local.virtualNetwork.id
  depends_on = [
    azurerm_virtual_network.studio
  ]
}

resource azurerm_private_dns_zone_virtual_network_link event_grid {
  name                  = "event-grid"
  resource_group_name   = azurerm_private_dns_zone.event_grid.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.event_grid.name
  virtual_network_id    = local.virtualNetwork.id
  depends_on = [
    azurerm_virtual_network.studio
  ]
}

resource azurerm_private_dns_zone_virtual_network_link app_config {
  name                  = "app-config"
  resource_group_name   = azurerm_private_dns_zone.app_config.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.app_config.name
  virtual_network_id    = local.virtualNetwork.id
  depends_on = [
    azurerm_virtual_network.studio
  ]
}

resource azurerm_private_dns_zone_virtual_network_link container_registry {
  count                 = data.terraform_remote_state.global.outputs.containerRegistry.enable ? 1 : 0
  name                  = "container-registry"
  resource_group_name   = azurerm_private_dns_zone.container_registry[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.container_registry[0].name
  virtual_network_id    = local.virtualNetwork.id
}

resource azurerm_private_dns_zone_virtual_network_link ai_services_open {
  count                 = data.terraform_remote_state.global.outputs.ai.services.enable ? 1 : 0
  name                  = "ai-services-open"
  resource_group_name   = azurerm_private_dns_zone.ai_services_open[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.ai_services_open[0].name
  virtual_network_id    = local.virtualNetwork.id
}

resource azurerm_private_dns_zone_virtual_network_link ai_services_cognitive {
  count                 = data.terraform_remote_state.global.outputs.ai.services.enable ? 1 : 0
  name                  = "ai-services-cognitive"
  resource_group_name   = azurerm_private_dns_zone.ai_services_cognitive[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.ai_services_cognitive[0].name
  virtual_network_id    = local.virtualNetwork.id
}

resource azurerm_private_dns_zone_virtual_network_link ai_search {
  count                 = data.terraform_remote_state.global.outputs.ai.search.enable ? 1 : 0
  name                  = "ai-search"
  resource_group_name   = azurerm_private_dns_zone.ai_search[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.ai_search[0].name
  virtual_network_id    = local.virtualNetwork.id
}

resource azurerm_private_dns_zone_virtual_network_link ai_machine_learning {
  count                 = data.terraform_remote_state.global.outputs.ai.machineLearning.enable ? 1 : 0
  name                  = "ai-machine-learning"
  resource_group_name   = azurerm_private_dns_zone.ai_machine_learning[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.ai_machine_learning[0].name
  virtual_network_id    = local.virtualNetwork.id
}

resource azurerm_private_dns_zone_virtual_network_link ai_machine_learning_notebook {
  count                 = data.terraform_remote_state.global.outputs.ai.machineLearning.enable ? 1 : 0
  name                  = "ai-machine-learning-notebook"
  resource_group_name   = azurerm_private_dns_zone.ai_machine_learning_notebook[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.ai_machine_learning_notebook[0].name
  virtual_network_id    = local.virtualNetwork.id
}
