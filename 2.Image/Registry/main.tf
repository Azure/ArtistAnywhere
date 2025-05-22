terraform {
  required_version = ">=1.12.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.29.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~>3.5.0"
    }
  }
  backend azurerm {
    key              = "2.Image.Registry"
    use_azuread_auth = true
  }
}

provider azurerm {
  features {
  }
  subscription_id     = data.terraform_remote_state.foundation.outputs.subscriptionId
  storage_use_azuread = true
}

variable resourceGroupName {
  type = string
}

data http client_address {
  url = "https://api.ipify.org?format=json"
}

data terraform_remote_state foundation {
  backend = "local"
  config = {
    path = "../../0.Foundation/terraform.tfstate"
  }
}

data terraform_remote_state network {
  backend = "azurerm"
  config = {
    subscription_id      = data.terraform_remote_state.foundation.outputs.subscriptionId
    resource_group_name  = data.terraform_remote_state.foundation.outputs.resourceGroup.name
    storage_account_name = data.terraform_remote_state.foundation.outputs.storage.account.name
    container_name       = data.terraform_remote_state.foundation.outputs.storage.containerName.terraformState
    key                  = "1.Network"
    use_azuread_auth     = true
  }
}

data azurerm_user_assigned_identity main {
  name                = data.terraform_remote_state.foundation.outputs.managedIdentity.name
  resource_group_name = data.terraform_remote_state.foundation.outputs.resourceGroup.name
}

data azurerm_virtual_network main {
  name                = data.terraform_remote_state.network.outputs.virtualNetwork.name
  resource_group_name = data.terraform_remote_state.network.outputs.virtualNetwork.resourceGroup.name
}

data azurerm_subnet main {
  name                 = "Cluster"
  resource_group_name  = data.azurerm_virtual_network.main.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.main.name
}

resource azurerm_resource_group image_registry {
  name     = var.resourceGroupName
  location = data.azurerm_virtual_network.main.location
  tags = {
    "AAA.Module" = "${basename(dirname(path.cwd))}.${basename(path.cwd)}"
  }
}
