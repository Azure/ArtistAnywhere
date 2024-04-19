################################################################################################
# API Management (https://learn.microsoft.com/azure/api-management/api-management-key-concepts #
################################################################################################

variable apiManagement {
  type = object({
    name = string
    tier = string
    publisher = object({
      name  = string
      email = string
    })
  })
}

data external account_user {
  program = ["az", "account", "show", "--query", "user"]
}

resource azurerm_api_management studio {
  name                 = var.apiManagement.name
  resource_group_name  = azurerm_resource_group.studio.name
  location             = azurerm_resource_group.studio.location
  sku_name             = var.apiManagement.tier
  publisher_name       = var.apiManagement.publisher.name == "" ? data.azurerm_subscription.studio.display_name : var.apiManagement.publisher.name
  publisher_email      = var.apiManagement.publisher.email == "" ? data.external.account_user.result.name : var.apiManagement.publisher.email
  virtual_network_type = "Internal"
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.farm.id
    ]
  }
  virtual_network_configuration {
    subnet_id = data.azurerm_subnet.studio.id
  }
}
