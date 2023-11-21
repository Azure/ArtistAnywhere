terraform {
  required_version = ">= 1.6.4"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.81.0"
    }
    azapi = {
      source = "azure/azapi"
      version = "~>1.10.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~>3.4.0"
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
  source = "../0.Global.Foundation/module"
}

variable resourceGroupName {
  type = string
}

variable binStorage {
  type = object({
    host = string
    auth = string
  })
  validation {
    condition     = var.binStorage.host != "" && var.binStorage.auth != ""
    error_message = "Missing required deployment configuration."
  }
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

data terraform_remote_state network {
  backend = "azurerm"
  config = {
    resource_group_name  = module.global.resourceGroupName
    storage_account_name = module.global.rootStorage.accountName
    container_name       = module.global.rootStorage.containerName.terraform
    key                  = "1.Virtual.Network"
  }
}

data azurerm_virtual_network studio {
  name                = var.existingNetwork.enable ? var.existingNetwork.name : data.terraform_remote_state.network.outputs.virtualNetwork.name
  resource_group_name = var.existingNetwork.enable ? var.existingNetwork.resourceGroupName : data.terraform_remote_state.network.outputs.virtualNetwork.resourceGroupName
}

data azurerm_subnet farm {
  name                 = var.existingNetwork.enable ? var.existingNetwork.subnetNameFarm : data.terraform_remote_state.network.outputs.virtualNetwork.subnets[data.terraform_remote_state.network.outputs.virtualNetwork.subnetIndex.farm].name
  resource_group_name  = data.azurerm_virtual_network.studio.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.studio.name
}

resource azurerm_resource_group image {
  name     = var.resourceGroupName
  location = module.global.regionName
}

output resourceGroupName {
  value = azurerm_resource_group.image.name
}
