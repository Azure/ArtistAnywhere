###################################################################################################
# Defender (https://learn.microsoft.com/azure/defender-for-cloud/defender-for-cloud-introduction) #
###################################################################################################

resource azurerm_security_center_workspace studio {
  scope        = "/subscriptions/${module.global.subscriptionId}"
  workspace_id = azurerm_log_analytics_workspace.studio.id
}
