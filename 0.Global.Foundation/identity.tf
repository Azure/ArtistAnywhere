#############################################################################################################
# Managed Identity (https://learn.microsoft.com/entra/identity/managed-identities-azure-resources/overview) #
#############################################################################################################

resource azurerm_user_assigned_identity studio {
  name                = module.global.managedIdentity.name
  resource_group_name = azurerm_resource_group.studio.name
  location            = azurerm_resource_group.studio.location
}

resource azurerm_role_assignment managed_identity_operator {
  role_definition_name = "Managed Identity Operator" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/identity#managed-identity-operator
  principal_id         = azurerm_user_assigned_identity.studio.principal_id
  scope                = azurerm_user_assigned_identity.studio.id
}

resource azurerm_role_assignment virtual_machine_contributor {
  role_definition_name = "Virtual Machine Contributor" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/compute#virtual-machine-contributor
  principal_id         = azurerm_user_assigned_identity.studio.principal_id
  scope                = "/subscriptions/${module.global.subscriptionId}"
}
