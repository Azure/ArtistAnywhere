terraform {
  required_version = ">=1.11.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.27.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>3.3.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~>3.5.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~>0.13.0"
    }
    azapi = {
      source = "azure/azapi"
      version = "~>2.3.0"
    }
  }
  backend azurerm {
    key              = "6.Compute.Cluster"
    use_azuread_auth = true
  }
}

provider azurerm {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id     = data.terraform_remote_state.core.outputs.subscriptionId
  storage_use_azuread = true
}

module core {
  source = "../0.Core.Foundation/config"
}

variable resourceGroupName {
  type = string
}

variable extendedZone {
  type = object({
    enable   = bool
    name     = string
    location = string
  })
}

variable virtualNetwork {
  type = object({
    name              = string
    subnetName        = string
    resourceGroupName = string
  })
}

variable activeDirectory {
  type = object({
    enable = bool
    domain = object({
      name = string
    })
    machine = object({
      name = string
      adminLogin = object({
        userName     = string
        userPassword = string
      })
    })
  })
}

variable containerRegistry {
  type = object({
    enable            = bool
    name              = string
    resourceGroupName = string
  })
}

data azurerm_subscription current {}

data terraform_remote_state core {
  backend = "local"
  config = {
    path = "../0.Core.Foundation/terraform.tfstate"
  }
}

data azurerm_user_assigned_identity studio {
  name                = data.terraform_remote_state.core.outputs.managedIdentity.name
  resource_group_name = data.terraform_remote_state.core.outputs.resourceGroup.name
}

data azurerm_key_vault studio {
  name                = data.terraform_remote_state.core.outputs.keyVault.name
  resource_group_name = data.terraform_remote_state.core.outputs.resourceGroup.name
}

data azurerm_key_vault_secret admin_username {
  name         = data.terraform_remote_state.core.outputs.keyVault.secretName.adminUsername
  key_vault_id = data.azurerm_key_vault.studio.id
}

data azurerm_key_vault_secret admin_password {
  name         = data.terraform_remote_state.core.outputs.keyVault.secretName.adminPassword
  key_vault_id = data.azurerm_key_vault.studio.id
}

data azurerm_key_vault_secret ssh_key_public {
  name         = data.terraform_remote_state.core.outputs.keyVault.secretName.sshKeyPublic
  key_vault_id = data.azurerm_key_vault.studio.id
}

data azurerm_application_insights studio {
  name                = data.terraform_remote_state.core.outputs.monitor.applicationInsights.name
  resource_group_name = data.terraform_remote_state.core.outputs.monitor.resourceGroup.name
}

data azurerm_app_configuration_keys studio {
  configuration_store_id = data.terraform_remote_state.core.outputs.appConfig.id
}

data azurerm_virtual_network studio {
  name                = var.virtualNetwork.name
  resource_group_name = var.virtualNetwork.resourceGroupName
}

data azurerm_virtual_network studio_extended {
  count               = var.extendedZone.enable ? 1 : 0
  name                = var.virtualNetwork.name
  resource_group_name = var.virtualNetwork.resourceGroupName
}

data azurerm_container_registry studio {
  count               = var.containerRegistry.enable ? 1 : 0
  name                = var.containerRegistry.name
  resource_group_name = var.containerRegistry.resourceGroupName
}

locals {
  activeDirectory = merge(var.activeDirectory, {
    machine = merge(var.activeDirectory.machine, {
      adminLogin = merge(var.activeDirectory.machine.adminLogin, {
        userName     = var.activeDirectory.machine.adminLogin.userName != "" ? var.activeDirectory.machine.adminLogin.userName : data.azurerm_key_vault_secret.admin_username.value
        userPassword = var.activeDirectory.machine.adminLogin.userPassword != "" ? var.activeDirectory.machine.adminLogin.userPassword : data.azurerm_key_vault_secret.admin_password.value
      })
    })
  })
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

resource azurerm_resource_group cluster {
  name     = var.resourceGroupName
  location = data.azurerm_virtual_network.studio.location
  tags = {
    AAA = basename(path.cwd)
  }
}

resource azurerm_resource_group cluster_container_app {
  count    = length(local.containerAppEnvironments) > 0 ? 1 : 0
  name     = "${var.resourceGroupName}.ContainerApp"
  location = data.azurerm_virtual_network.studio.location
  tags = {
    AAA = basename(path.cwd)
  }
}

resource azurerm_resource_group cluster_container_aks {
  count    = var.kubernetes.enable ? 1 : 0
  name     = "${var.resourceGroupName}.Kubernetes"
  location = data.azurerm_virtual_network.studio.location
  tags = {
    AAA = basename(path.cwd)
  }
}

output container {
  value = {
    appEnvironments = [
      for appEnvironment in azurerm_container_app_environment.studio: {
        name              = appEnvironment.name
        resourceGroupName = appEnvironment.resource_group_name
        domain            = appEnvironment.default_domain
        address = {
          host   = appEnvironment.static_ip_address
          docker = appEnvironment.docker_bridge_cidr
          platform = {
            host = appEnvironment.platform_reserved_cidr
            dns  = appEnvironment.platform_reserved_dns_ip_address
          }
        }
      }
    ]
    kubernetesClusters = [
      for kubernetesCluster in azurerm_kubernetes_cluster.studio: {
        name              = kubernetesCluster.name
        resourceGroupName = kubernetesCluster.resource_group_name
      }
    ]
  }
}
