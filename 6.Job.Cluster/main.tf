terraform {
  required_version = ">=1.12.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.29.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~>2.4.0"
    }
  }
  backend azurerm {
    key              = "6.Job.Cluster"
    use_azuread_auth = true
  }
}

provider azurerm {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id     = data.terraform_remote_state.foundation.outputs.subscriptionId
  storage_use_azuread = true
}

module config {
  source = "../0.Foundation/config"
}

variable resourceGroupName {
  type = string
}

variable virtualNetwork {
  type = object({
    name              = string
    subnetName        = string
    edgeZoneName      = string
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

data terraform_remote_state foundation {
  backend = "local"
  config = {
    path = "../0.Foundation/terraform.tfstate"
  }
}

data azurerm_user_assigned_identity main {
  name                = data.terraform_remote_state.foundation.outputs.managedIdentity.name
  resource_group_name = data.terraform_remote_state.foundation.outputs.resourceGroup.name
}

data azurerm_key_vault main {
  name                = data.terraform_remote_state.foundation.outputs.keyVault.name
  resource_group_name = data.terraform_remote_state.foundation.outputs.resourceGroup.name
}

data azurerm_key_vault_secret admin_username {
  name         = data.terraform_remote_state.foundation.outputs.keyVault.secretName.adminUsername
  key_vault_id = data.azurerm_key_vault.main.id
}

data azurerm_key_vault_secret admin_password {
  name         = data.terraform_remote_state.foundation.outputs.keyVault.secretName.adminPassword
  key_vault_id = data.azurerm_key_vault.main.id
}

data azurerm_key_vault_secret ssh_key_public {
  name         = data.terraform_remote_state.foundation.outputs.keyVault.secretName.sshKeyPublic
  key_vault_id = data.azurerm_key_vault.main.id
}

data azurerm_application_insights main {
  name                = data.terraform_remote_state.foundation.outputs.monitor.applicationInsights.name
  resource_group_name = data.terraform_remote_state.foundation.outputs.monitor.resourceGroup.name
}

data azurerm_app_configuration_keys main {
  configuration_store_id = data.terraform_remote_state.foundation.outputs.appConfig.id
}

data azurerm_virtual_network main {
  name                = var.virtualNetwork.name
  resource_group_name = var.virtualNetwork.resourceGroupName
}

data azurerm_container_registry main {
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

resource azurerm_resource_group cluster {
  name     = var.resourceGroupName
  location = data.azurerm_virtual_network.main.location
  tags = {
    "AAA.Module" = basename(path.cwd)
  }
}

resource azurerm_resource_group cluster_fleet {
  count    = length(local.computeFleets) > 0 ? 1 : 0
  name     = "${var.resourceGroupName}.Fleet"
  location = data.azurerm_virtual_network.main.location
  tags = {
    "AAA.Module" = basename(path.cwd)
  }
}

resource azurerm_resource_group cluster_container {
  count    = length(local.containerAppEnvironments) > 0 ? 1 : 0
  name     = "${var.resourceGroupName}.Container"
  location = data.azurerm_virtual_network.main.location
  tags = {
    "AAA.Module" = basename(path.cwd)
  }
}

output cluster {
  value = {
    vmScaleSets = concat([
      for vmScaleSet in data.azurerm_virtual_machine_scale_set.main : {
        name              = vmScaleSet.name
        resourceGroupName = vmScaleSet.resource_group_name
        flexOrchestration = false
      }
    ], [
      for vmScaleSet in data.azurerm_orchestrated_virtual_machine_scale_set.main : {
        name              = vmScaleSet.name
        resourceGroupName = vmScaleSet.resource_group_name
        flexOrchestration = true
      }
    ])
    computeFleets = [
      for computeFleet in local.computeFleets : {
        name              = computeFleet.name
        resourceGroupName = azurerm_resource_group.cluster_fleet[0].name
      }
    ]
    appEnvironments = [
      for appEnvironment in azurerm_container_app_environment.main : {
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
  }
}
