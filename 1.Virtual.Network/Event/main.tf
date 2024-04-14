terraform {
  required_version = ">= 1.8.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.99.0"
    }
  }
  backend azurerm {
    key = "1.Virtual.Network.Event"
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

variable event {
  type = object({
    grid = object({
      name = string
    })
    hub = object({
      name = string
      tier = string
    })
  })
}

data http client_address {
  url = "https://api.ipify.org?format=json"
}

data azurerm_client_config studio {}

data azurerm_user_assigned_identity studio {
  name                = module.global.managedIdentity.name
  resource_group_name = module.global.resourceGroupName
}

data azurerm_key_vault studio {
  count               = module.global.keyVault.enable ? 1 : 0
  name                = module.global.keyVault.name
  resource_group_name = module.global.resourceGroupName
}

data azurerm_storage_account studio {
  name                = module.global.storage.accountName
  resource_group_name = module.global.resourceGroupName
}

data terraform_remote_state network {
  backend = "azurerm"
  config = {
    resource_group_name  = module.global.resourceGroupName
    storage_account_name = module.global.storage.accountName
    container_name       = module.global.storage.containerName.terraformState
    key                  = "1.Virtual.Network"
  }
}

locals {
  virtualNetworks              = data.terraform_remote_state.network.outputs.virtualNetworks
  virtualNetworksSubnetCompute = data.terraform_remote_state.network.outputs.virtualNetworksSubnetCompute
}

resource azurerm_resource_group event {
  name     = "${module.global.resourceGroupName}.Event"
  location = module.global.resourceLocation.region
}
