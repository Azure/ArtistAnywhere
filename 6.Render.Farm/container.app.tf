##############################################################################
# Container Apps (https://learn.microsoft.com/azure/container-apps/overview) #
##############################################################################

variable containerApp {
  type = object({
    enable = bool
    environment = object({
      name = string
      workloadProfile = object({
        name = string
        type = string
      })
    })
  })
}

resource azurerm_container_app_environment studio {
  count                          = var.containerApp.enable ? 1 : 0
  name                           = var.containerApp.environment.name
  resource_group_name            = azurerm_resource_group.farm.name
  location                       = azurerm_resource_group.farm.location
  log_analytics_workspace_id     = data.azurerm_log_analytics_workspace.studio[0].id
  infrastructure_subnet_id       = "${data.azurerm_virtual_network.studio_region.id}/subnets/Farm"
  internal_load_balancer_enabled = false
  zone_redundancy_enabled        = false
  workload_profile {
    name                  = var.containerApp.environment.workloadProfile.name
    workload_profile_type = var.containerApp.environment.workloadProfile.type
  }
}
