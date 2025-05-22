terraform {
  required_version = ">=1.12.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.29.0"
    }
  }
  backend azurerm {
    key              = "1.Network"
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

variable resourceGroupName {
  type = string
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

data azurerm_storage_account main {
  name                = data.terraform_remote_state.foundation.outputs.storage.account.name
  resource_group_name = data.terraform_remote_state.foundation.outputs.resourceGroup.name
}

data azurerm_key_vault main {
  name                = data.terraform_remote_state.foundation.outputs.keyVault.name
  resource_group_name = data.terraform_remote_state.foundation.outputs.resourceGroup.name
}

data azurerm_key_vault_secret gateway_connection {
  name         = data.terraform_remote_state.foundation.outputs.keyVault.secretName.gatewayConnection
  key_vault_id = data.azurerm_key_vault.main.id
}

data azurerm_app_configuration main {
  name                = data.terraform_remote_state.foundation.outputs.appConfig.name
  resource_group_name = data.terraform_remote_state.foundation.outputs.resourceGroup.name
}

data azurerm_monitor_workspace main {
  name                = data.terraform_remote_state.foundation.outputs.monitor.workspace.name
  resource_group_name = data.terraform_remote_state.foundation.outputs.monitor.resourceGroup.name
}

data azurerm_dashboard_grafana main {
  name                = data.terraform_remote_state.foundation.outputs.monitor.workspace.name
  resource_group_name = data.terraform_remote_state.foundation.outputs.monitor.resourceGroup.name
}

resource azurerm_resource_group network {
  name     = var.resourceGroupName
  location = local.virtualNetwork.location
  tags = {
    "AAA.Module" = basename(path.cwd)
  }
}

resource azurerm_resource_group network_regions {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.key => virtualNetwork
  }
  name     = each.value.resourceGroup.name
  location = each.value.location
  tags = {
    "AAA.Module" = basename(path.cwd)
  }
}
