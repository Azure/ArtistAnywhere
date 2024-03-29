terraform {
  required_version = ">= 1.7.3"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.97.1"
    }
    azapi = {
      source = "azure/azapi"
      version = "~>1.12.1"
    }
  }
  backend azurerm {
    key = "2.Image.Builder"
  }
}

provider azurerm {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

module global {
  source = "../0.Global.Foundation/config"
}

variable resourceGroupName {
  type = string
}

variable existingKeyVault {
  type = object({
    enable            = bool
    name              = string
    resourceGroupName = string
  })
}

variable existingNetwork {
  type = object({
    enable            = bool
    name              = string
    subnetName        = string
    resourceGroupName = string
  })
}

data azurerm_user_assigned_identity studio {
  name                = module.global.managedIdentity.name
  resource_group_name = module.global.resourceGroupName
}

data azurerm_key_vault studio {
  count               = module.global.keyVault.enable ? 1 : 0
  name                = var.existingKeyVault.enable ? var.existingKeyVault.name : module.global.keyVault.name
  resource_group_name = var.existingKeyVault.enable ? var.existingKeyVault.resourceGroupName : module.global.resourceGroupName
}

data azurerm_key_vault_secret admin_username {
  count        = module.global.keyVault.enable ? 1 : 0
  name         = module.global.keyVault.secretName.adminUsername
  key_vault_id = data.azurerm_key_vault.studio[0].id
}

data azurerm_key_vault_secret admin_password {
  count        = module.global.keyVault.enable ? 1 : 0
  name         = module.global.keyVault.secretName.adminPassword
  key_vault_id = data.azurerm_key_vault.studio[0].id
}

data azurerm_key_vault_secret database_username {
  count        = module.global.keyVault.enable ? 1 : 0
  name         = module.global.keyVault.secretName.databaseUsername
  key_vault_id = data.azurerm_key_vault.studio[0].id
}

data azurerm_key_vault_secret database_password {
  count        = module.global.keyVault.enable ? 1 : 0
  name         = module.global.keyVault.secretName.databasePassword
  key_vault_id = data.azurerm_key_vault.studio[0].id
}

data terraform_remote_state network {
  backend = "azurerm"
  config = {
    resource_group_name  = module.global.resourceGroupName
    storage_account_name = module.global.rootStorage.accountName
    container_name       = module.global.rootStorage.containerName.terraformState
    key                  = "1.Virtual.Network"
  }
}

data azurerm_virtual_network studio {
  name                = var.existingNetwork.enable ? var.existingNetwork.name : data.terraform_remote_state.network.outputs.virtualNetworkRegional.name
  resource_group_name = var.existingNetwork.enable ? var.existingNetwork.resourceGroupName : data.terraform_remote_state.network.outputs.virtualNetworkRegional.resourceGroupName
}

data azurerm_subnet farm {
  name                 = var.existingNetwork.enable ? var.existingNetwork.subnetName : "Farm"
  resource_group_name  = data.azurerm_virtual_network.studio.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.studio.name
}

data azurerm_resource_group network {
  name = data.azurerm_virtual_network.studio.resource_group_name
}

locals {
  regionNames = var.existingNetwork.enable ? [module.global.resourceLocation.region] : [
    for virtualNetwork in data.terraform_remote_state.network.outputs.virtualNetworksRegional : virtualNetwork.regionName
  ]
}

resource azurerm_resource_group image {
  name     = var.resourceGroupName
  location = module.global.resourceLocation.region
}
