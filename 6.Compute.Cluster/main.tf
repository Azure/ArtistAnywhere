terraform {
  required_version = ">=1.11.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.26.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>3.3.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~>3.4.0"
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
  subscription_id     = data.terraform_remote_state.core.outputs.subscription.id
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
    enable            = bool
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

data azurerm_user_assigned_identity studio {
  name                = module.core.managedIdentity.name
  resource_group_name = data.terraform_remote_state.core.outputs.resourceGroup.name
}

data azurerm_key_vault studio {
  name                = module.core.keyVault.name
  resource_group_name = data.terraform_remote_state.core.outputs.resourceGroup.name
}

data azurerm_key_vault_secret admin_username {
  name         = module.core.keyVault.secretName.adminUsername
  key_vault_id = data.azurerm_key_vault.studio.id
}

data azurerm_key_vault_secret admin_password {
  name         = module.core.keyVault.secretName.adminPassword
  key_vault_id = data.azurerm_key_vault.studio.id
}

data azurerm_key_vault_secret ssh_key_public {
  name         = module.core.keyVault.secretName.sshKeyPublic
  key_vault_id = data.azurerm_key_vault.studio.id
}

data terraform_remote_state core {
  backend = "local"
  config = {
    path = "../0.Core.Foundation/terraform.tfstate"
  }
}

data terraform_remote_state network {
  backend = "azurerm"
  config = {
    subscription_id      = data.terraform_remote_state.core.outputs.subscription.id
    resource_group_name  = data.terraform_remote_state.core.outputs.resourceGroup.name
    storage_account_name = data.terraform_remote_state.core.outputs.storage.account.name
    container_name       = data.terraform_remote_state.core.outputs.storage.containerName.terraformState
    key                  = "1.Virtual.Network"
    use_azuread_auth     = true
  }
}

data azurerm_virtual_network studio {
  name                = var.virtualNetwork.enable ? var.virtualNetwork.name : data.terraform_remote_state.network.outputs.virtualNetwork.default.name
  resource_group_name = var.virtualNetwork.enable ? var.virtualNetwork.resourceGroupName : data.terraform_remote_state.network.outputs.virtualNetwork.default.resourceGroup.name
}

data azurerm_virtual_network studio_extended {
  count               = var.extendedZone.enable ? 1 : 0
  name                = var.virtualNetwork.enable ? var.virtualNetwork.name : data.terraform_remote_state.network.outputs.virtualNetwork.extended.name
  resource_group_name = var.virtualNetwork.enable ? var.virtualNetwork.resourceGroupName : data.terraform_remote_state.network.outputs.virtualNetwork.extended.resourceGroup.name
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
  location = module.core.resourceLocation.name
  tags = {
    AAA = basename(path.cwd)
  }
}

resource azurerm_resource_group cluster_container_app {
  count    = length(local.containerAppEnvironments) > 0 ? 1 : 0
  name     = "${var.resourceGroupName}.ContainerApp"
  location = module.core.resourceLocation.name
  tags = {
    AAA = basename(path.cwd)
  }
}

resource azurerm_resource_group cluster_container_aks {
  count    = var.kubernetes.enable ? 1 : 0
  name     = "${var.resourceGroupName}.Kubernetes"
  location = module.core.resourceLocation.name
  tags = {
    AAA = basename(path.cwd)
  }
}
