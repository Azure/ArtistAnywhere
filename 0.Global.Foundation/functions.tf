#####################################################
# https://learn.microsoft.com/azure/azure-functions #
#####################################################

variable functionApp {
  type = object({
    name = string
    servicePlan = object({
      osType      = string
      computeType = string
    })
    runtime = object({
      name    = string
      version = string
    })
    instance = object({
      memoryMB = number
      maxCount = number
    })
  })
}

resource azurerm_storage_container functions {
  name                 = "functions"
  storage_account_name = azurerm_storage_account.studio[0].name
}

resource azurerm_service_plan functions {
  name                = var.functionApp.name
  resource_group_name = azurerm_resource_group.studio.name
  location            = azurerm_resource_group.studio.location
  sku_name            = var.functionApp.servicePlan.computeType
  os_type             = var.functionApp.servicePlan.osType
}

resource azapi_resource functions {
  name      = var.functionApp.name
  type      = "Microsoft.Web/sites@2023-12-01"
  parent_id = azurerm_resource_group.studio.id
  location  = azurerm_service_plan.functions.location
  identity {
    type = "SystemAssigned, UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.studio.id
    ]
  }
  body = jsonencode({
    kind = "functionapp,linux"
    properties = {
      sku          = "FlexConsumption"
      serverFarmId = azurerm_service_plan.functions.id
      functionAppConfig = {
        runtime = {
          name    = var.functionApp.runtime.name
          version = var.functionApp.runtime.version
        }
        deployment = {
          storage = {
            type  = "blobContainer"
            value = azurerm_storage_container.functions.id
            authentication = {
              type = "SystemAssignedIdentity"
            }
          }
        }
        scaleAndConcurrency = {
          instanceMemoryMB     = var.functionApp.instance.memoryMB
          maximumInstanceCount = var.functionApp.instance.maxCount
        }
      }
      siteconfig = {
        http20enabled = true
      }
    }
  })
  schema_validation_enabled = false
}
