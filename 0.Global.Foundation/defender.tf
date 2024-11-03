###################################################################################################
# Defender (https://learn.microsoft.com/azure/defender-for-cloud/defender-for-cloud-introduction) #
###################################################################################################

resource azurerm_security_center_workspace studio {
  scope        = "/subscriptions/${module.global.subscriptionId}"
  workspace_id = azurerm_log_analytics_workspace.studio.id
}

resource azurerm_security_center_storage_defender studio {
  storage_account_id                          = azurerm_storage_account.studio.id
  malware_scanning_on_upload_enabled          = module.global.defender.storage.malwareScanning.enable
  malware_scanning_on_upload_cap_gb_per_month = module.global.defender.storage.malwareScanning.maxPerMonthGB
  sensitive_data_discovery_enabled            = module.global.defender.storage.sensitiveDataDiscovery.enable
}
