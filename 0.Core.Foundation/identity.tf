#############################################################################################################
# Managed Identity (https://learn.microsoft.com/entra/identity/managed-identities-azure-resources/overview) #
#############################################################################################################

variable managedIdentity {
  type = object({
    name = string
  })
}

resource azurerm_user_assigned_identity studio {
  name                = var.managedIdentity.name
  resource_group_name = azurerm_resource_group.studio.name
  location            = azurerm_resource_group.studio.location
}

resource azurerm_role_assignment managed_identity_operator {
  role_definition_name = "Managed Identity Operator" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/identity#managed-identity-operator
  principal_id         = azurerm_user_assigned_identity.studio.principal_id
  scope                = azurerm_user_assigned_identity.studio.id
}

resource azurerm_role_assignment storage_blob_data_owner {
  role_definition_name = "Storage Blob Data Owner" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/storage#storage-blob-data-owner
  principal_id         = azurerm_user_assigned_identity.studio.principal_id
  scope                = azurerm_storage_account.studio.id
}

resource azurerm_role_assignment virtual_machine_contributor {
  role_definition_name = "Virtual Machine Contributor" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/compute#virtual-machine-contributor
  principal_id         = azurerm_user_assigned_identity.studio.principal_id
  scope                = "/subscriptions/${data.azurerm_subscription.current.subscription_id}"
}

output managedIdentity {
  value = {
    id          = azurerm_user_assigned_identity.studio.id
    name        = azurerm_user_assigned_identity.studio.name
    principalId = azurerm_user_assigned_identity.studio.principal_id
  }
}
