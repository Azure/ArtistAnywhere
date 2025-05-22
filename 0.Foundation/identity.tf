#############################################################################################################
# Managed Identity (https://learn.microsoft.com/entra/identity/managed-identities-azure-resources/overview) #
#############################################################################################################

variable managedIdentity {
  type = object({
    name = string
  })
}

resource azurerm_user_assigned_identity main {
  name                = var.managedIdentity.name
  resource_group_name = azurerm_resource_group.foundation.name
  location            = azurerm_resource_group.foundation.location
}

resource azurerm_role_assignment managed_identity_operator {
  role_definition_name = "Managed Identity Operator" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/identity#managed-identity-operator
  principal_id         = azurerm_user_assigned_identity.main.principal_id
  scope                = azurerm_user_assigned_identity.main.id
}

resource azurerm_role_assignment virtual_machine_contributor {
  role_definition_name = "Virtual Machine Contributor" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/compute#virtual-machine-contributor
  principal_id         = azurerm_user_assigned_identity.main.principal_id
  scope                = "/subscriptions/${data.azurerm_subscription.current.subscription_id}"
}

output managedIdentity {
  value = {
    name = azurerm_user_assigned_identity.main.name
  }
}
