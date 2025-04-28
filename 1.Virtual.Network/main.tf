terraform {
  required_version = ">=1.11.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.27.0"
    }
  }
  backend azurerm {
    key              = "1.Virtual.Network"
    use_azuread_auth = true
  }
}

provider azurerm {
  features {
  }
  subscription_id     = data.terraform_remote_state.core.outputs.subscriptionId
  storage_use_azuread = true
}

variable resourceGroupName {
  type = string
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

data azurerm_storage_account studio {
  name                = data.terraform_remote_state.core.outputs.storage.account.name
  resource_group_name = data.terraform_remote_state.core.outputs.resourceGroup.name
}

data azurerm_key_vault studio {
  name                = data.terraform_remote_state.core.outputs.keyVault.name
  resource_group_name = data.terraform_remote_state.core.outputs.resourceGroup.name
}

data azurerm_key_vault_secret gateway_connection {
  name         = data.terraform_remote_state.core.outputs.keyVault.secretName.gatewayConnection
  key_vault_id = data.azurerm_key_vault.studio.id
}

data azurerm_app_configuration studio {
  name                = data.terraform_remote_state.core.outputs.appConfig.name
  resource_group_name = data.terraform_remote_state.core.outputs.resourceGroup.name
}

data azurerm_monitor_workspace studio {
  name                = data.terraform_remote_state.core.outputs.monitor.workspace.name
  resource_group_name = data.terraform_remote_state.core.outputs.monitor.resourceGroup.name
}

data azurerm_dashboard_grafana studio {
  name                = data.terraform_remote_state.core.outputs.monitor.workspace.name
  resource_group_name = data.terraform_remote_state.core.outputs.monitor.resourceGroup.name
}

resource azurerm_resource_group network {
  name     = var.resourceGroupName
  location = local.virtualNetwork.location
  tags = {
    AAA = basename(path.cwd)
  }
}

resource azurerm_resource_group network_regions {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.key => virtualNetwork
  }
  name     = each.value.resourceGroup.name
  location = each.value.location
  tags = {
    AAA = basename(path.cwd)
  }
}
