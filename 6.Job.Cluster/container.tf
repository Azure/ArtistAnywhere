##############################################################################
# Container Apps (https://learn.microsoft.com/azure/container-apps/overview) #
##############################################################################

variable containerAppEnvironments {
  type = list(object({
    enable = bool
    name   = string
    workloadProfiles = list(object({
      name = string
      type = string
      scaleUnit = object({
        minCount = number
        maxCount = number
      })
    }))
    network = object({
      subnetName = string
      internalOnly = object({
        enable = bool
      })
    })
    apps = list(object({
      enable = bool
      name   = string
      container = object({
        name   = string
        image  = string
        memory = string
        cpu    = number
      })
      revisionMode = object({
        type = string
      })
    }))
    zoneRedundancy = object({
      enable = bool
    })
  }))
}

locals {
  containerAppEnvironments = [
    for appEnvironment in var.containerAppEnvironments : merge(appEnvironment, {
      network = merge(appEnvironment.network, {
        subnetId = "${data.azurerm_virtual_network.main.id}/subnets/${appEnvironment.network.subnetName}"
      })
    }) if appEnvironment.enable
  ]
  containerApps = flatten([
    for appEnvironment in local.containerAppEnvironments : [
      for containerApp in appEnvironment.apps : merge(containerApp, {
        key             = "${appEnvironment.name}-${containerApp.name}"
        environmentName = appEnvironment.name
      }) if containerApp.enable
    ]
  ])
}

resource azurerm_container_app_environment main {
  for_each = {
    for appEnvironment in local.containerAppEnvironments : appEnvironment.name => appEnvironment
  }
  name                                        = each.value.name
  resource_group_name                         = azurerm_resource_group.cluster_container[0].name
  location                                    = azurerm_resource_group.cluster_container[0].location
  log_analytics_workspace_id                  = data.terraform_remote_state.foundation.outputs.monitor.logAnalytics.id
  dapr_application_insights_connection_string = data.azurerm_application_insights.main.connection_string
  internal_load_balancer_enabled              = each.value.network.internalOnly.enable
  infrastructure_subnet_id                    = each.value.network.subnetId
  zone_redundancy_enabled                     = each.value.zoneRedundancy.enable
  infrastructure_resource_group_name          = length(each.value.workloadProfiles) > 0 ? "${azurerm_resource_group.cluster_container[0].name}.${each.value.network.subnetName}" : null
  dynamic workload_profile {
    for_each = each.value.workloadProfiles
    content {
      name                  = workload_profile.value["name"]
      workload_profile_type = workload_profile.value["type"]
      minimum_count         = workload_profile.value["scaleUnit"]["minCount"] > 0 ? workload_profile.value["scaleUnit"]["minCount"] : null
      maximum_count         = workload_profile.value["scaleUnit"]["maxCount"] > 0 ? workload_profile.value["scaleUnit"]["maxCount"] : null
    }
  }
}

resource azurerm_container_app main {
  for_each = {
    for containerApp in local.containerApps : containerApp.key => containerApp
  }
  name                         = each.value.name
  resource_group_name          = azurerm_resource_group.cluster_container[0].name
  container_app_environment_id = azurerm_container_app_environment.main[each.value.environmentName].id
  revision_mode                = each.value.revisionMode.type
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.main.id
    ]
  }
  registry {
    server   = data.azurerm_container_registry.main[0].login_server
    identity = data.azurerm_user_assigned_identity.main.id
  }
  template {
    container {
      name   = each.value.container.name
      image  = each.value.container.image
      memory = each.value.container.memory
      cpu    = each.value.container.cpu
    }
  }
  depends_on = [
    azurerm_container_app_environment.main
  ]
}
