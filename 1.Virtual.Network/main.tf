terraform {
  required_version = ">= 1.8.4"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.108.0"
    }
  }
  backend azurerm {
    key = "1.Virtual.Network"
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

variable subscriptionId {
  type = object({
    terraformState = string
  })
}

data azurerm_client_config studio {}

data azurerm_user_assigned_identity studio {
  name                = module.global.managedIdentity.name
  resource_group_name = module.global.resourceGroupName
}

data azurerm_storage_account studio {
  count               = terraform.workspace != "shared" ? 1 : 0
  name                = module.global.storage.accountName
  resource_group_name = module.global.resourceGroupName
}

data azurerm_key_vault studio {
  count               = module.global.keyVault.enable ? 1 : 0
  name                = module.global.keyVault.name
  resource_group_name = module.global.resourceGroupName
}

data azurerm_key_vault_secret gateway_connection {
  count        = module.global.keyVault.enable ? 1 : 0
  name         = module.global.keyVault.secretName.gatewayConnection
  key_vault_id = data.azurerm_key_vault.studio[0].id
}

data azurerm_app_configuration studio {
  count               = module.global.appConfig.enable ? 1 : 0
  name                = module.global.appConfig.name
  resource_group_name = module.global.resourceGroupName
}

data terraform_remote_state ai {
  count   = terraform.workspace != "shared" ? 1 : 0
  backend = "azurerm"
  config = {
    subscription_id      = local.subscriptionId.terraformState
    resource_group_name  = module.global.resourceGroupName
    storage_account_name = module.global.storage.accountName
    container_name       = module.global.storage.containerName.terraformState
    key                  = "0.Global.Foundation.AI"
  }
}

locals {
  subscriptionId = {
    terraformState = var.subscriptionId.terraformState != "" ? var.subscriptionId.terraformState : data.azurerm_client_config.studio.subscription_id
  }
}

resource azurerm_resource_group network {
  name     = var.resourceGroupName
  location = local.virtualNetwork.regionName
}

resource azurerm_resource_group network_regions {
  for_each = {
    for virtualNetwork in local.virtualNetworksExtended : virtualNetwork.key => virtualNetwork
  }
  name     = each.value.resourceGroupName
  location = each.value.regionName
}
