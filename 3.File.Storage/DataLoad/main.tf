terraform {
  required_version = ">=1.11.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.23.0"
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
  subscription_id     = data.terraform_remote_state.core.outputs.subscription.id
  storage_use_azuread = true
}

module core {
  source = "../../0.Core.Foundation/config"
}

variable resourceGroupName {
  type = string
}

variable regionName {
  type = string
}

data azurerm_user_assigned_identity studio {
  name                = module.core.managedIdentity.name
  resource_group_name = data.terraform_remote_state.core.outputs.resourceGroup.name
}

data azurerm_key_vault studio {
  name                = module.core.keyVault.name
  resource_group_name = data.terraform_remote_state.core.outputs.resourceGroup.name
}

data azurerm_key_vault_secret admin_username {
  name         = module.core.keyVault.secretName.adminUsername
  key_vault_id = data.azurerm_key_vault.studio.id
}

data azurerm_key_vault_secret admin_password {
  name         = module.core.keyVault.secretName.adminPassword
  key_vault_id = data.azurerm_key_vault.studio.id
}

data azurerm_key_vault_secret ssh_key_public {
  name         = module.core.keyVault.secretName.sshKeyPublic
  key_vault_id = data.azurerm_key_vault.studio.id
}

data terraform_remote_state core {
  backend = "local"
  config = {
    path = "../../0.Core.Foundation/terraform.tfstate"
  }
}

data terraform_remote_state network {
  backend = "azurerm"
  config = {
    subscription_id      = data.terraform_remote_state.core.outputs.subscription.id
    resource_group_name  = data.terraform_remote_state.core.outputs.resourceGroup.name
    storage_account_name = data.terraform_remote_state.core.outputs.storage.account.name
    container_name       = data.terraform_remote_state.core.outputs.storage.containerName.terraformState
    key                  = "1.Virtual.Network"
    use_azuread_auth     = true
  }
}

data azurerm_resource_group dns {
  name = data.terraform_remote_state.network.outputs.dns.privateZone.resourceGroup.name
}

data azurerm_virtual_network studio {
  name                = data.terraform_remote_state.network.outputs.virtualNetwork.core.name
  resource_group_name = var.regionName != "" ? "${data.azurerm_resource_group.dns.name}.${var.regionName}" : data.terraform_remote_state.network.outputs.virtualNetwork.core.resourceGroup.name
}

data azurerm_subnet storage {
  name                 = "Storage"
  resource_group_name  = data.azurerm_virtual_network.studio.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.studio.name
}

locals {
  location = var.regionName != "" ? var.regionName : module.core.resourceLocation.name
}

resource azurerm_resource_group storage_data_load {
  name     = var.resourceGroupName
  location = local.location
  tags = {
    AAA = basename(path.cwd)
  }
}
