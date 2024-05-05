terraform {
  required_version = ">= 1.8.2"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.101.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "~>2.3.3"
    }
  }
  backend azurerm {
    key = "1.Virtual.Network.API"
  }
}

provider azurerm {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    api_management {
      purge_soft_delete_on_destroy = true
      recover_soft_deleted         = true
    }
  }
}

module global {
  source = "../../0.Global.Foundation/config"
}

data azurerm_subscription studio {}

data azurerm_user_assigned_identity studio {
  name                = module.global.managedIdentity.name
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

data azurerm_virtual_network studio_region {
  name                = data.terraform_remote_state.network.outputs.virtualNetworks[0].name
  resource_group_name = data.terraform_remote_state.network.outputs.virtualNetworks[0].resourceGroupName
}

data azurerm_subnet farm {
  name                 = "Farm"
  resource_group_name  = data.azurerm_virtual_network.studio_region.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.studio_region.name
}

locals {
  virtualNetworks              = data.terraform_remote_state.network.outputs.virtualNetworks
  virtualNetworksSubnetCompute = data.terraform_remote_state.network.outputs.virtualNetworksSubnetCompute
}

resource azurerm_resource_group api {
  name     = "${module.global.resourceGroupName}.API"
  location = module.global.resourceLocation.regionName
}
