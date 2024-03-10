terraform {
  required_version = ">= 1.7.3"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.95.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>2.47.0"
    }
    azapi = {
      source = "azure/azapi"
      version = "~>1.12.1"
    }
    http = {
      source  = "hashicorp/http"
      version = "~>3.4.2"
    }
  }
  backend azurerm {
    key = "1.Virtual.Network.CosmosDB"
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
  source = "../../0.Global.Foundation/config"
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

data http client_address {
  url = "https://api.ipify.org?format=json"
}

data azurerm_user_assigned_identity studio {
  name                = module.global.managedIdentity.name
  resource_group_name = module.global.resourceGroupName
}

data azurerm_key_vault studio {
  name                = var.existingKeyVault.enable ? var.existingKeyVault.name : module.global.keyVault.name
  resource_group_name = var.existingKeyVault.enable ? var.existingKeyVault.resourceGroupName : module.global.resourceGroupName
}

data azurerm_key_vault_secret admin_username {
  name         = module.global.keyVault.secretName.adminUsername
  key_vault_id = data.azurerm_key_vault.studio.id
}

data azurerm_key_vault_secret admin_password {
  name         = module.global.keyVault.secretName.adminPassword
  key_vault_id = data.azurerm_key_vault.studio.id
}

data azurerm_key_vault_secret database_username {
  name         = module.global.keyVault.secretName.databaseUsername
  key_vault_id = data.azurerm_key_vault.studio.id
}

data azurerm_key_vault_secret database_password {
  name         = module.global.keyVault.secretName.databasePassword
  key_vault_id = data.azurerm_key_vault.studio.id
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
  name                = var.existingNetwork.enable ? var.existingNetwork.name : data.terraform_remote_state.network.outputs.virtualNetwork.name
  resource_group_name = var.existingNetwork.enable ? var.existingNetwork.resourceGroupName : data.terraform_remote_state.network.outputs.virtualNetwork.resourceGroupName
}

data azurerm_subnet data {
  name                 = var.existingNetwork.enable ? var.existingNetwork.subnetName : "Data"
  resource_group_name  = data.azurerm_virtual_network.studio.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.studio.name
}

data azurerm_subnet data_cassandra {
  name                 = var.existingNetwork.enable ? var.existingNetwork.subnetName : "DataCassandra"
  resource_group_name  = data.azurerm_virtual_network.studio.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.studio.name
}

locals {
  regionNames = var.existingNetwork.enable ? [module.global.regionName] : [
    for virtualNetwork in data.terraform_remote_state.network.outputs.virtualNetworks : virtualNetwork.regionName
  ]
}

resource azurerm_resource_group database {
  name     = var.resourceGroupName
  location = module.global.regionName
}
