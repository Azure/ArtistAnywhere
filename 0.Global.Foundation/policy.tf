#########################################################################
# Policy (https://learn.microsoft.com/azure/governance/policy/overview) #
#########################################################################

resource azurerm_subscription_policy_assignment disable_password_authentication {
  name                 = azurerm_policy_definition.disable_password_authentication.name
  policy_definition_id = azurerm_policy_definition.disable_password_authentication.id
  subscription_id      = "/subscriptions/${data.azurerm_client_config.studio.subscription_id}"
}

resource azurerm_policy_definition disable_password_authentication {
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
