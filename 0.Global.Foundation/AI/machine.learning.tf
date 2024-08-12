#################################################################################################################
# Machine Learning (https://learn.microsoft.com/azure/machine-learning/overview-what-is-azure-machine-learning) #
#################################################################################################################

resource azurerm_resource_group ai_machine_learning {
  count    = var.ai.machineLearning.enable ? 1 : 0
  name     = "${azurerm_resource_group.ai.name}.MachineLearning"
  location = azurerm_resource_group.ai.location
}

resource azurerm_machine_learning_workspace ai {
  count                          = var.ai.machineLearning.enable ? 1 : 0
  name                           = var.ai.machineLearning.workspace.name
  resource_group_name            = azurerm_resource_group.ai_machine_learning[0].name
  location                       = azurerm_resource_group.ai_machine_learning[0].location
  kind                           = var.ai.machineLearning.workspace.type
  sku_name                       = var.ai.machineLearning.workspace.tier
  key_vault_id                   = data.azurerm_key_vault.studio.id
  storage_account_id             = data.azurerm_storage_account.studio.id
  primary_user_assigned_identity = data.azurerm_user_assigned_identity.studio.id
  application_insights_id        = data.azurerm_application_insights.studio[0].id
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
}
