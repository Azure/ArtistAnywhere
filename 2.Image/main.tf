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
    time = {
      source  = "hashicorp/time"
      version = "~>0.13.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~>2.4.0"
    }
  }
  backend azurerm {
    key              = "2.Image"
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
  source = "../0.Foundation/config"
}

variable resourceGroupName {
  type = string
}

variable virtualNetwork {
  type = object({
    name              = string
    subnetName        = string
    resourceGroupName = string
  })
}

data azurerm_client_config current {}

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

data azurerm_key_vault_secret service_username {
  name         = data.terraform_remote_state.foundation.outputs.keyVault.secretName.serviceUsername
  key_vault_id = data.azurerm_key_vault.main.id
}

data azurerm_key_vault_secret service_password {
  name         = data.terraform_remote_state.foundation.outputs.keyVault.secretName.servicePassword
  key_vault_id = data.azurerm_key_vault.main.id
}

data azurerm_app_configuration_keys main {
  configuration_store_id = data.terraform_remote_state.foundation.outputs.appConfig.id
}

data azurerm_virtual_network main {
  name                = var.virtualNetwork.name
  resource_group_name = var.virtualNetwork.resourceGroupName
}

data azurerm_subnet main {
  name                 = var.virtualNetwork.subnetName
  resource_group_name  = data.azurerm_virtual_network.main.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.main.name
}

resource azurerm_resource_group image_builder {
  name     = "${var.resourceGroupName}.Builder"
  location = data.azurerm_virtual_network.main.location
  tags = {
    "AAA.Module" = basename(path.cwd)
  }
}

resource azurerm_resource_group image_gallery {
  name     = "${var.resourceGroupName}.Gallery"
  location = data.azurerm_virtual_network.main.location
  tags = {
    "AAA.Module" = basename(path.cwd)
  }
}
