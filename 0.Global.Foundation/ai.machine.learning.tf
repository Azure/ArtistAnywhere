#################################################################################################################
# Machine Learning (https://learn.microsoft.com/azure/machine-learning/overview-what-is-azure-machine-learning) #
#################################################################################################################

resource azurerm_resource_group ai_machine_learning {
  count    = var.ai.machineLearning.enable && module.global.ai.enable ? 1 : 0
  name     = "${azurerm_resource_group.studio_ai[0].name}.MachineLearning"
  location = azurerm_resource_group.studio_ai[0].location
}

resource azurerm_machine_learning_workspace studio {
  count                   = var.ai.machineLearning.enable && module.global.ai.enable ? 1 : 0
  name                    = var.ai.machineLearning.workspace.name
  resource_group_name     = azurerm_resource_group.ai_machine_learning[0].name
  location                = azurerm_resource_group.ai_machine_learning[0].location
  kind                    = var.ai.machineLearning.workspace.tier
  storage_account_id      = azurerm_storage_account.studio.id
  key_vault_id            = azurerm_key_vault.studio[0].id
  application_insights_id = azurerm_application_insights.studio[0].id
  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.studio.id
    ]
  }
}
