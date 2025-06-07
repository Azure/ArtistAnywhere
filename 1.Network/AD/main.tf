terraform {
  required_version = ">=1.12.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.32.0"
    }
  }
  backend azurerm {
    key              = "1.Network.AD"
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
  name                = data.terraform_remote_state.network.outputs.virtualNetwork.name
  resource_group_name = data.terraform_remote_state.network.outputs.virtualNetwork.resourceGroup.name
}

data azurerm_subnet identity {
  name                 = "Identity"
  resource_group_name  = data.azurerm_virtual_network.main.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.main.name
}

locals {
  activeDirectory = merge(var.activeDirectory, {
    machine = merge(var.activeDirectory.machine, {
      adminLogin = merge(var.activeDirectory.machine.adminLogin, {
        userName     = var.activeDirectory.machine.adminLogin.userName != "" ? var.activeDirectory.machine.adminLogin.userName : data.azurerm_key_vault_secret.admin_username.value
        userPassword = var.activeDirectory.machine.adminLogin.userPassword != "" ? var.activeDirectory.machine.adminLogin.userPassword : data.azurerm_key_vault_secret.admin_password.value
      })
    })
  })
}

resource azurerm_resource_group active_directory {
  name     = var.resourceGroupName
  location = data.azurerm_virtual_network.main.location
  tags = {
    "AAA.Module" = "${basename(dirname(path.cwd))}.${basename(path.cwd)}"
  }
}
