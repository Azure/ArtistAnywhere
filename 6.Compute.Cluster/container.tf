####################################################################################
# Container Apps     (https://learn.microsoft.com/azure/container-apps/overview)   #
# Kubernetes Fleet   (https://learn.microsoft.com/azure/kubernetes-fleet/overview) #
# Kubernetes Service (https://learn.microsoft.com/azure/aks/what-is-aks)           #
####################################################################################

variable containerAppEnvironments {
  type = list(object({
    enable = bool
    name   = string
    workloadProfile = object({
      name = string
      type = string
      instanceCount = object({
        minimum = number
        maximum = number
      })
    })
    network = object({
      subnetName = string
      internalOnly = object({
        enable = bool
      })
      locationExtended = object({
        enable = bool
      })
    })
    registry = object({
      host = string
      login = object({
        userName     = string
        userPassword = string
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

variable kubernetes {
  type = object({
    enable = bool
    fleetManager = object({
      name      = string
      dnsPrefix = string
    })
    clusters = list(object({
      enable    = bool
      name      = string
      dnsPrefix = string
      systemNodePool = object({
        name = string
        machine = object({
          size  = string
          count = number
        })
      })
      userNodePools = list(object({
        name = string
        machine = object({
          size  = string
          count = number
        })
        spot = object({
          enable         = bool
          evictionPolicy = string
        })
      }))
    }))
  })
}

data azurerm_application_insights studio {
  name                = data.terraform_remote_state.core.outputs.monitor.applicationInsights.name
  resource_group_name = data.terraform_remote_state.core.outputs.monitor.resourceGroup.name
}

data azurerm_container_registry studio {
  count               = var.containerRegistry.enable ? 1 : 0
  name                = var.containerRegistry.name
  resource_group_name = var.containerRegistry.resourceGroupName
}

locals {
  containerAppEnvironments = [
    for containerAppEnvironment in var.containerAppEnvironments : merge(containerAppEnvironment, {
      network = merge(containerAppEnvironment.network, {
        subnetId = "${containerAppEnvironment.network.locationExtended.enable ? data.azurerm_virtual_network.studio_extended[0].id : data.azurerm_virtual_network.studio.id}/subnets/${var.virtualNetwork.enable ? var.virtualNetwork.subnetName : containerAppEnvironment.network.subnetName}"
      })
    }) if containerAppEnvironment.enable
  ]
  containerApps = flatten([
    for containerAppEnvironment in local.containerAppEnvironments : [
      for containerApp in containerAppEnvironment.apps : merge(containerApp, {
        environmentName   = containerAppEnvironment.name
        containerRegistry = containerAppEnvironment.registry
      }) if containerApp.enable
    ]
  ])
  kubernetesUserNodePools = flatten([
    for kubernetesCluster in var.kubernetes.clusters : [
      for userNodePool in kubernetesCluster.userNodePools : merge(userNodePool, {
        clusterName = kubernetesCluster.name
      })
    ] if kubernetesCluster.enable
  ])
}

resource azurerm_role_assignment container_registry_reader {
  count                = length(local.containerApps) > 0 || length(local.kubernetesUserNodePools) > 0 ? 1 : 0
  role_definition_name = "AcrPull" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/containers#acrpull
  principal_id         = data.azurerm_user_assigned_identity.studio.principal_id
  scope                = data.azurerm_container_registry.studio[0].id
}

resource time_sleep container_registry_rbac {
  count           = length(local.containerApps) > 0 || length(local.kubernetesUserNodePools) > 0 ? 1 : 0
  create_duration = "30s"
  depends_on = [
    azurerm_role_assignment.container_registry_reader
  ]
}

##############################################################################
# Container Apps (https://learn.microsoft.com/azure/container-apps/overview) #
##############################################################################

resource azurerm_container_app_environment studio {
  for_each = {
    for containerAppEnvironment in local.containerAppEnvironments : containerAppEnvironment.name => containerAppEnvironment
  }
  name                                        = each.value.name
  resource_group_name                         = azurerm_resource_group.cluster_container_app[0].name
  location                                    = azurerm_resource_group.cluster_container_app[0].location
  infrastructure_resource_group_name          = "${azurerm_resource_group.cluster_container_app[0].name}.Managed"
  log_analytics_workspace_id                  = data.terraform_remote_state.core.outputs.monitor.logAnalytics.id
  dapr_application_insights_connection_string = data.azurerm_application_insights.studio.connection_string
  internal_load_balancer_enabled              = each.value.network.internalOnly.enable
  infrastructure_subnet_id                    = each.value.network.subnetId
  zone_redundancy_enabled                     = each.value.zoneRedundancy.enable
  workload_profile {
    name                  = each.value.workloadProfile.name
    workload_profile_type = each.value.workloadProfile.type
    minimum_count         = each.value.workloadProfile.instanceCount.minimum > 0 ? each.value.workloadProfile.instanceCount.minimum : null
    maximum_count         = each.value.workloadProfile.instanceCount.maximum > 0 ? each.value.workloadProfile.instanceCount.maximum : null
  }
}

resource azurerm_container_app studio {
  for_each = {
    for containerApp in local.containerApps : containerApp.name => containerApp
  }
  name                         = each.value.name
  resource_group_name          = azurerm_resource_group.cluster_container_app[0].name
  container_app_environment_id = azurerm_container_app_environment.studio[each.value.environmentName].id
  revision_mode                = each.value.revisionMode.type
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  registry {
    server               = each.value.containerRegistry.host
    identity             = each.value.containerRegistry.login.userName == "" ? data.azurerm_user_assigned_identity.studio.id : null
    username             = each.value.containerRegistry.login.userName != "" ? each.value.containerRegistry.login.userName : null
    password_secret_name = each.value.containerRegistry.login.userPassword != "" ? each.value.containerRegistry.login.userPassword : null
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
    time_sleep.container_registry_rbac,
    azurerm_container_app_environment.studio
  ]
}

###################################################################################
# Kubernetes Fleet   (https://learn.microsoft.com/azure/kubernetes-fleet/overview) #
# Kubernetes Service (https://learn.microsoft.com/azure/aks/what-is-aks)           #
####################################################################################

resource azapi_resource fleet_manager {
  count     = var.kubernetes.enable ? 1 : 0
  name      = var.kubernetes.fleetManager.name
  parent_id = azurerm_resource_group.cluster_container_aks[0].id
  location  = azurerm_resource_group.cluster_container_aks[0].location
  type      = "Microsoft.ContainerService/fleets@2025-03-01"
  body = {
    properties = {
      hubProfile = {
        dnsPrefix = var.kubernetes.fleetManager.dnsPrefix != "" ? var.kubernetes.fleetManager.dnsPrefix : var.kubernetes.fleetManager.name
      }
      # nodeResourceGroup = "${azurerm_resource_group.cluster_container_aks[0].name}.Managed"
    }
  }
  schema_validation_enabled = false
}

# DO NOT USE (DEPRECATED) - Creates a fleet manager WITHOUT a hub cluster!
# resource azurerm_kubernetes_fleet_manager studio {
#   count               = var.kubernete.enable ? 1 : 0
#   name                = var.kubernetes.fleetManager.name
#   resource_group_name = azurerm_resource_group.cluster_container_aks[0].name
#   location            = azurerm_resource_group.cluster_container_aks[0].location
#   hub_profile {
#     dns_prefix = var.kubernetes.fleetManager.dnsPrefix != "" ? var.kubernetes.fleetManager.dnsPrefix : var.kubernetes.fleetManager.name
#   }
# }

resource azurerm_kubernetes_cluster studio {
  for_each = {
    for kubernetesCluster in var.kubernetes.clusters : kubernetesCluster.name => kubernetesCluster if var.kubernetes.enable && kubernetesCluster.enable
  }
  name                    = each.value.name
  resource_group_name     = azurerm_resource_group.cluster_container_aks[0].name
  location                = azurerm_resource_group.cluster_container_aks[0].location
  dns_prefix              = each.value.dnsPrefix == "" ? "studio" : each.value.dnsPrefix
  private_cluster_enabled = true
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  default_node_pool {
    name                         = each.value.systemNodePool.name
    vm_size                      = each.value.systemNodePool.machine.size
    node_count                   = each.value.systemNodePool.machine.count
    vnet_subnet_id               = each.value.network.subnetId
    only_critical_addons_enabled = true
  }
}

resource azurerm_kubernetes_cluster_node_pool studio {
  for_each = {
    for userNodePool in local.kubernetesUserNodePools : "${userNodePool.clusterName}-${userNodePool.name}" => userNodePool
  }
  name                  = each.value.name
  kubernetes_cluster_id = "${azurerm_resource_group.cluster_container_aks[0].id}/providers/Microsoft.ContainerService/managedClusters/${each.value.clusterName}"
  vm_size               = each.value.machineSize
  node_count            = each.value.machineCount
  priority              = each.value.spotEnable ? "Spot" : "Regular"
  eviction_policy       = each.value.spotEnable ? each.value.spotEvictionPolicy : null
  depends_on = [
    azurerm_kubernetes_cluster.studio
  ]
}
