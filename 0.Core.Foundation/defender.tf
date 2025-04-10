###################################################################################################
# Defender (https://learn.microsoft.com/azure/defender-for-cloud/defender-for-cloud-introduction) #
###################################################################################################

variable defender {
  type = object({
    storage = object({
      malwareScanning = object({
        enable        = bool
        maxPerMonthGB = number
      })
      sensitiveDataDiscovery = object({
        enable = bool
      })
    })
  })
}

resource azurerm_security_center_workspace studio {
  workspace_id = azurerm_log_analytics_workspace.studio.id
  scope        = "/subscriptions/${data.azurerm_subscription.current.subscription_id}"
}

resource azurerm_security_center_storage_defender studio {
  storage_account_id                          = azurerm_storage_account.studio.id
  malware_scanning_on_upload_enabled          = var.defender.storage.malwareScanning.enable
  malware_scanning_on_upload_cap_gb_per_month = var.defender.storage.malwareScanning.maxPerMonthGB
  sensitive_data_discovery_enabled            = var.defender.storage.sensitiveDataDiscovery.enable
}

output defender {
  value = var.defender
}
