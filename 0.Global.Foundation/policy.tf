#########################################################################
# Policy (https://learn.microsoft.com/azure/governance/policy/overview) #
#########################################################################

variable policy {
  type = object({
    disablePasswordAuthLinux = object({
      enable = bool
    })
  })
}

resource azurerm_subscription_policy_assignment disable_password_auth_linux {
  count                = var.policy.disablePasswordAuthLinux.enable ? 1 : 0
  name                 = azurerm_policy_definition.disable_password_auth_linux.name
  policy_definition_id = azurerm_policy_definition.disable_password_auth_linux.id
  subscription_id      = "/subscriptions/${data.azurerm_client_config.studio.subscription_id}"
  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.studio.id
    ]
  }
  # resource_selectors {
  #   selectors {
  #     kind = "resourceType"
  #     in   = ["Linux"]
  #   }
  # }
}

resource azurerm_policy_definition disable_password_auth_linux {
  name         = "Disable Linux VM Password Authentication"
  display_name = "Disable password authentication for all Linux Virtual Machines"
  policy_type  = "Custom"
  mode         = "Indexed"
  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.Compute/virtualMachines"
        },
        {
          field  = "Microsoft.Compute/virtualMachines/storageProfile.osDisk.osType"
          equals = "Linux"
        },
        {
          field  = "Microsoft.Compute/virtualMachines/osProfile.linuxConfiguration.disablePasswordAuthentication"
          exists = "false"
        }
      ]
    },
    then = {
      effect = "deny"
    }
  })
}
