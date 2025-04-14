####################################################################################
# Kubernetes Fleet   (https://learn.microsoft.com/azure/kubernetes-fleet/overview) #
# Kubernetes Service (https://learn.microsoft.com/azure/aks/what-is-aks)           #
####################################################################################

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

locals {
  kubernetesUserNodePools = flatten([
    for kubernetesCluster in var.kubernetes.clusters : [
      for userNodePool in kubernetesCluster.userNodePools : merge(userNodePool, {
        key         = "${kubernetesCluster.name}-${userNodePool.name}"
        clusterName = kubernetesCluster.name
      })
    ] if kubernetesCluster.enable
  ])
}

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
    for userNodePool in local.kubernetesUserNodePools : userNodePool.key => userNodePool
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
