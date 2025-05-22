terraform {
  required_version = ">=1.12.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.29.0"
    }
  }
  backend azurerm {
    key              = "3.File.Storage.DataLoad"
    use_azuread_auth = true
  }
}

provider azurerm {
  features {
  }
  subscription_id     = data.terraform_remote_state.foundation.outputs.subscriptionId
  storage_use_azuread = true
}

module config {
  source = "../../0.Foundation/config"
}

variable resourceGroupName {
  type = string
}

variable virtualNetwork {
  type = object({
    name              = string
    subnetName        = string
    resourceGroupName = string
    privateDNS = object({
      zoneName          = string
      resourceGroupName = string
    })
  })
}

data terraform_remote_state foundation {
  backend = "local"
  config = {
    path = "../../0.Foundation/terraform.tfstate"
  }
}

data azurerm_user_assigned_identity main {
  name                = data.terraform_remote_state.foundation.outputs.managedIdentity.name
  resource_group_name = data.terraform_remote_state.foundation.outputs.resourceGroup.name
}

data azurerm_key_vault main {
  name                = data.terraform_remote_state.foundation.outputs.keyVault.name
  resource_group_name = data.terraform_remote_state.foundation.outputs.resourceGroup.name
}

data azurerm_key_vault_secret admin_username {
  name         = data.terraform_remote_state.foundation.outputs.keyVault.secretName.adminUsername
  key_vault_id = data.azurerm_key_vault.main.id
}

data azurerm_key_vault_secret admin_password {
  name         = data.terraform_remote_state.foundation.outputs.keyVault.secretName.adminPassword
  key_vault_id = data.azurerm_key_vault.main.id
}

data azurerm_key_vault_secret ssh_key_public {
  name         = data.terraform_remote_state.foundation.outputs.keyVault.secretName.sshKeyPublic
  key_vault_id = data.azurerm_key_vault.main.id
}

data azurerm_app_configuration_keys main {
  configuration_store_id = data.terraform_remote_state.foundation.outputs.appConfig.id
}

data azurerm_virtual_network main {
  name                = var.virtualNetwork.name
  resource_group_name = var.virtualNetwork.resourceGroupName
}

data azurerm_subnet storage {
  name                 = var.virtualNetwork.subnetName
  resource_group_name  = data.azurerm_virtual_network.main.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.main.name
}

resource azurerm_resource_group storage_data_load {
  name     = var.resourceGroupName
  location = data.azurerm_virtual_network.main.location
  tags = {
    "AAA.Module" = "${basename(dirname(path.cwd))}.${basename(path.cwd)}"
  }
}
