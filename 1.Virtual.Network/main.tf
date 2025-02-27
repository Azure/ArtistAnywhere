terraform {
  required_version = ">=1.10.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.20.0"
    }
  }
  backend azurerm {
    key              = "1.Virtual.Network"
    use_azuread_auth = true
  }
}

provider azurerm {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id     = module.global.subscriptionId
  storage_use_azuread = true
}

module global {
  source = "../0.Global.Foundation/config"
}

variable resourceGroupName {
  type = string
}

data azurerm_user_assigned_identity studio {
  name                = module.global.managedIdentity.name
  resource_group_name = module.global.resourceGroupName
}

data azurerm_storage_account studio {
  name                = module.global.storage.accountName
  resource_group_name = module.global.resourceGroupName
}

data azurerm_key_vault studio {
  name                = module.global.keyVault.name
  resource_group_name = module.global.resourceGroupName
}

data azurerm_key_vault_secret gateway_connection {
  name         = module.global.keyVault.secretName.gatewayConnection
  key_vault_id = data.azurerm_key_vault.studio.id
}

# data azurerm_eventgrid_namespace studio {
#   name                = module.global.message.eventGrid.name
#   resource_group_name = data.terraform_remote_state.global.outputs.message.resourceGroupName
# }

data azurerm_eventhub_namespace studio {
  name                = module.global.message.eventHub.name
  resource_group_name = data.terraform_remote_state.global.outputs.message.resourceGroupName
}

data terraform_remote_state global {
  backend = "local"
  config = {
    path = "../0.Global.Foundation/terraform.tfstate"
  }
}

resource azurerm_resource_group network {
  name     = var.resourceGroupName
  location = local.virtualNetwork.regionName
  tags = {
    AAA = basename(path.cwd)
  }
}

resource azurerm_resource_group network_regions {
  for_each = {
    for virtualNetwork in local.virtualNetworksExtended : virtualNetwork.key => virtualNetwork
  }
  name     = each.value.resourceGroupName
  location = each.value.regionName
  tags = {
    AAA = basename(path.cwd)
  }
}
