#################################################################
# Functions (https://learn.microsoft.com/azure/azure-functions) #
#################################################################

variable functionApp {
  type = object({
    enable = bool
    name   = string
    servicePlan = object({
      type = string
      tier = string
    })
    runtime = object({
      name    = string
      version = string
    })
    scale = object({
      instance = object({
        memoryMB = number
        maxCount = number
      })
    })
  })
}

resource azurerm_storage_container function_app {
  count                = var.functionApp.enable ? 1 : 0
  name                 = "function-app"
  storage_account_name = data.azurerm_storage_account.studio.name
}

resource azapi_resource function_app_farm {
  count     = var.functionApp.enable ? 1 : 0
  name      = var.functionApp.name
  type      = "Microsoft.Web/serverFarms@2023-12-01"
  parent_id = azurerm_resource_group.app.id
  location  = azurerm_resource_group.app.location
  body = jsonencode({
      kind = "functionapp"
      sku = {
        name = var.functionApp.servicePlan.type
        tier = var.functionApp.servicePlan.tier
      },
      properties = {
        reserved = true
      }
  })
  schema_validation_enabled = false
}

resource azapi_resource function_app_site {
  count     = var.functionApp.enable ? 1 : 0
  name      = var.functionApp.name
  type      = "Microsoft.Web/sites@2023-12-01"
  parent_id = azapi_resource.function_app_farm[0].parent_id
  location  = azapi_resource.function_app_farm[0].location
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  body = jsonencode({
    kind = "functionapp,linux"
    properties = {
      sku          = var.functionApp.servicePlan.tier
      serverFarmId = azapi_resource.function_app_farm[0].id
      functionAppConfig = {
        runtime = {
          name    = var.functionApp.runtime.name
          version = var.functionApp.runtime.version
        }
        scaleAndConcurrency = {
          instanceMemoryMB     = var.functionApp.scale.instance.memoryMB
          maximumInstanceCount = var.functionApp.scale.instance.maxCount
        }
        deployment = {
          storage = {
            type  = "blobContainer"
            value = "${data.azurerm_storage_account.studio.primary_blob_endpoint}${azurerm_storage_container.function_app[0].name}"
            authentication = {
              type                           = "UserAssignedIdentity"
              userAssignedIdentityResourceId = data.azurerm_user_assigned_identity.studio.id
            }
          }
        }
      }
      siteconfig = {
        appSettings = [
          {
            name  = "AzureWebJobsStorage__accountName"
            value = data.azurerm_storage_account.studio.name
          },
          {
            name  = "ApplicationInsights_Connection_String"
            value = data.azurerm_application_insights.studio[0].connection_string
          }
        ]
        ipSecurityRestrictions = [
          {
            name      = "Allow Client Address"
            action    = "Allow"
            ipAddress = "${jsondecode(data.http.client_address.response_body).ip}/32"
          }
        ]
        http20enabled = true
      }
      publicNetworkAccess = "Enabled"
      httpsOnly = true
    }
  })
  schema_validation_enabled = false
}

resource azurerm_app_service_virtual_network_swift_connection function_app_site {
  count          = var.functionApp.enable ? 1 : 0
  app_service_id = azapi_resource.function_app_site[0].id
  subnet_id      = data.azurerm_subnet.app.id
}

resource azurerm_private_dns_zone function_app {
  count               = var.functionApp.enable ? 1 : 0
  name                = "privatelink.azurewebsites.net"
  resource_group_name = azurerm_resource_group.app.name
}

resource azurerm_private_dns_zone_virtual_network_link function_app {
  count                 = var.functionApp.enable ? 1 : 0
  name                  = "function-app"
  resource_group_name   = azurerm_private_dns_zone.function_app[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.function_app[0].name
  virtual_network_id    = data.azurerm_virtual_network.studio_region.id
}

resource azurerm_private_endpoint function_app {
  count               = var.functionApp.enable ? 1 : 0
  name                = azapi_resource.function_app_site[0].name
  resource_group_name = azurerm_resource_group.app.name
  location            = azurerm_resource_group.app.location
  subnet_id           = data.azurerm_subnet.farm.id
  private_service_connection {
    name                           = azapi_resource.function_app_site[0].name
    private_connection_resource_id = azapi_resource.function_app_site[0].id
    is_manual_connection           = false
    subresource_names = [
      "sites"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.function_app[0].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.function_app[0].id
    ]
  }
}
