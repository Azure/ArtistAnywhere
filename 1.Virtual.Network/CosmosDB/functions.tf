#####################################################
# https://learn.microsoft.com/azure/azure-functions #
#####################################################

variable functionApp {
  type = object({
    name = string
    servicePlan = object({
      computeType = string
    })
    fileShare = object({
      name   = string
      sizeGB = number
    })
    siteConfig = object({
      alwaysOn = bool
    })
  })
}

data azurerm_application_insights studio {
  count               = module.global.monitor.enable && var.noSQL.enable ? 1 : 0
  name                = module.global.monitor.name
  resource_group_name = module.global.resourceGroupName
}

data azurerm_storage_account studio {
  count               = var.noSQL.enable ? 1 : 0
  name                = module.global.rootStorage.accountName
  resource_group_name = module.global.resourceGroupName
}

resource azurerm_storage_share studio {
  count                = var.noSQL.enable ? 1 : 0
  name                 = var.functionApp.fileShare.name
  quota                = var.functionApp.fileShare.sizeGB
  storage_account_name = data.azurerm_storage_account.studio[0].name
}

resource azurerm_service_plan studio {
  count               = var.noSQL.enable ? 1 : 0
  name                = var.functionApp.name
  resource_group_name = azurerm_resource_group.database.name
  location            = var.cosmosDB.geoLocations[0].regionName
  sku_name            = var.functionApp.servicePlan.computeType
  os_type             = "Windows"
}

resource azurerm_windows_function_app studio {
  count                                          = var.noSQL.enable ? 1 : 0
  name                                           = var.functionApp.name
  resource_group_name                            = azurerm_resource_group.database.name
  location                                       = azurerm_resource_group.database.location
  service_plan_id                                = azurerm_service_plan.studio[0].id
  storage_account_name                           = data.azurerm_storage_account.studio[0].name
  storage_uses_managed_identity                  = true
  builtin_logging_enabled                        = true
  https_only                                     = true
  webdeploy_publish_basic_authentication_enabled = false
  ftp_publish_basic_authentication_enabled       = false
  public_network_access_enabled                  = false
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
#   storage_account {
#     name         = azurerm_storage_account.studio.name
#     account_name = azurerm_storage_account.studio.name
#     access_key   = azurerm_storage_account.studio.primary_access_key
#     share_name   = azurerm_storage_share.studio.name
#     type         = "AzureFiles"
#   }
  site_config {
#     always_on                              = var.functionApp.siteConfig.alwaysOn
    application_insights_connection_string = module.global.monitor.enable ? data.azurerm_application_insights.studio[0].connection_string : null
    application_insights_key               = module.global.monitor.enable ? data.azurerm_application_insights.studio[0].instrumentation_key : null
    health_check_path                      = "/"
    use_32_bit_worker                      = false
    http2_enabled                          = true
    cors {
      allowed_origins = [
        "https://portal.azure.com"
      ]
    }
  }
#   app_settings = {
#     AzureWebJobsStorage = "DefaultEndpointsProtocol=https;AccountName=${azurerm_storage_account.studio.name};AccountKey=${azurerm_storage_account.studio.primary_access_key}"
#   }
}
