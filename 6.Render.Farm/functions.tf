#####################################################
# https://learn.microsoft.com/azure/azure-functions #
#####################################################

variable functionApp {
  type = object({
    enable        = bool
    name          = string
    subnetName    = string
    fileShareName = string
    servicePlan = object({
      computeTier = string
      workerCount = number
      alwaysOn    = bool
    })
  })
}

data azurerm_application_insights studio {
  count               = var.functionApp.enable ? 1 : 0
  name                = module.global.monitor.name
  resource_group_name = module.global.resourceGroupName
}

data azurerm_storage_share studio {
  count                = var.functionApp.enable ? 1 : 0
  name                 = var.existingStorage.enable ? var.existingStorage.fileShareName : var.functionApp.fileShareName
  storage_account_name = data.azurerm_storage_account.studio.name
}

resource azurerm_private_dns_zone functions {
  count               = var.functionApp.enable ? 1 : 0
  name                = "privatelink.azurewebsites.net"
  resource_group_name = azurerm_resource_group.farm.name
}

resource azurerm_private_dns_zone_virtual_network_link functions {
  count                 = var.functionApp.enable ? 1 : 0
  name                  = "functions"
  resource_group_name   = azurerm_private_dns_zone.functions[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.functions[0].name
  virtual_network_id    = data.azurerm_virtual_network.studio.id
}

resource azurerm_private_endpoint function_app {
  count               = var.functionApp.enable ? 1 : 0
  name                = "${azurerm_windows_function_app.studio[0].name}-${azurerm_private_dns_zone_virtual_network_link.functions[0].name}"
  resource_group_name = azurerm_resource_group.farm.name
  location            = azurerm_resource_group.farm.location
  subnet_id           = "${data.azurerm_virtual_network.studio.id}/subnets/${var.existingNetwork.enable ? var.existingNetwork.subnetName : var.functionApp.subnetName}"
  private_service_connection {
    name                           = azurerm_windows_function_app.studio[0].name
    private_connection_resource_id = azurerm_windows_function_app.studio[0].id
    is_manual_connection           = false
    subresource_names = [
      "sites"
    ]
  }
  private_dns_zone_group {
    name = azurerm_windows_function_app.studio[0].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.functions[0].id
    ]
  }
  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.functions
  ]
}

resource azurerm_service_plan studio {
  count               = var.functionApp.enable ? 1 : 0
  name                = var.functionApp.name
  resource_group_name = azurerm_resource_group.farm.name
  location            = azurerm_resource_group.farm.location
  sku_name            = var.functionApp.servicePlan.computeTier
  worker_count        = var.functionApp.servicePlan.workerCount
  os_type             = "Windows"
}

resource azurerm_windows_function_app studio {
  count                         = var.functionApp.enable ? 1 : 0
  name                          = var.functionApp.name
  resource_group_name           = azurerm_resource_group.farm.name
  location                      = azurerm_resource_group.farm.location
  service_plan_id               = azurerm_service_plan.studio[0].id
  virtual_network_subnet_id     = "${data.azurerm_virtual_network.studio.id}/subnets/${var.existingNetwork.enable ? var.existingNetwork.subnetName : var.functionApp.subnetName}"
  storage_account_name          = data.azurerm_storage_account.studio.name
  storage_uses_managed_identity = true
  public_network_access_enabled = false
  builtin_logging_enabled       = true
  https_only                    = true
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  storage_account {
    name         = data.azurerm_storage_account.studio.name
    account_name = data.azurerm_storage_account.studio.name
    access_key   = data.azurerm_storage_account.studio.secondary_access_key
    share_name   = data.azurerm_storage_share.studio[0].name
    type         = "AzureFiles"
  }
  site_config {
    always_on                              = var.functionApp.servicePlan.alwaysOn
    application_insights_connection_string = data.azurerm_application_insights.studio[0].connection_string
    application_insights_key               = data.azurerm_application_insights.studio[0].instrumentation_key
    health_check_path                      = "/"
    use_32_bit_worker                      = false
    http2_enabled                          = true
    vnet_route_all_enabled                 = true
    cors {
      allowed_origins = [
        "https://portal.azure.com"
      ]
    }
  }
  app_settings = {
    AzureWebJobsStorage     = "DefaultEndpointsProtocol=https;AccountName=${data.azurerm_storage_account.studio.name};AccountKey=${data.azurerm_storage_account.studio.secondary_access_key}"
    AzureOpenAI_ApiEndpoint = azurerm_cognitive_account.open_ai[0].endpoint
    AzureOpenAI_ApiKey      = azurerm_cognitive_account.open_ai[0].secondary_access_key
  }
}

resource azurerm_function_app_function image_generate {
  count           = var.functionApp.enable ? 1 : 0
  name            = "image-generate"
  language        = "CSharp"
  function_app_id = azurerm_windows_function_app.studio[0].id
  config_json = jsonencode({
    bindings = [
      {
        name      = "request"
        type      = "httpTrigger"
        direction = "in"
        authLevel = "function"
        methods = [
          "post"
        ]
      },
      {
        name      = "$return"
        type      = "http"
        direction = "out"
      }
    ]
  })
  test_data = jsonencode({
    chatDeployment = {
      modelName      = var.azureOpenAI.chatDeployment.model.name
      historyContext = var.azureOpenAI.chatDeployment.session.context
      requestMessage = var.azureOpenAI.chatDeployment.session.request
    }
    imageGeneration = {
      description = var.azureOpenAI.imageGeneration.description
      height      = var.azureOpenAI.imageGeneration.height
      width       = var.azureOpenAI.imageGeneration.width
    }
  })
  file {
    name    = "function.proj"
    content = file("image.generate/function.proj")
  }
  file {
    name    = "run.csx"
    content = file("image.generate/run.csx")
  }
}
