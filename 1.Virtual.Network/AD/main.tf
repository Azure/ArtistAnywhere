terraform {
  required_version = ">=1.11.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.27.0"
    }
  }
  backend azurerm {
    key              = "1.Virtual.Network.AD"
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

data terraform_remote_state core {
  backend = "local"
  config = {
    path = "../../0.Core.Foundation/terraform.tfstate"
  }
}

data terraform_remote_state network {
  backend = "azurerm"
  config = {
    subscription_id      = data.terraform_remote_state.core.outputs.subscriptionId
    resource_group_name  = data.terraform_remote_state.core.outputs.resourceGroup.name
    storage_account_name = data.terraform_remote_state.core.outputs.storage.account.name
    container_name       = data.terraform_remote_state.core.outputs.storage.containerName.terraformState
    key                  = "1.Virtual.Network"
    use_azuread_auth     = true
  }
}

data azurerm_user_assigned_identity studio {
  name                = data.terraform_remote_state.core.outputs.managedIdentity.name
  resource_group_name = data.terraform_remote_state.core.outputs.resourceGroup.name
}

data azurerm_key_vault studio {
  name                = data.terraform_remote_state.core.outputs.keyVault.name
  resource_group_name = data.terraform_remote_state.core.outputs.resourceGroup.name
}

data azurerm_key_vault_secret admin_username {
  name         = data.terraform_remote_state.core.outputs.keyVault.secretName.adminUsername
  key_vault_id = data.azurerm_key_vault.studio.id
}

data azurerm_key_vault_secret admin_password {
  name         = data.terraform_remote_state.core.outputs.keyVault.secretName.adminPassword
  key_vault_id = data.azurerm_key_vault.studio.id
}

data azurerm_key_vault_secret ssh_key_public {
  name         = data.terraform_remote_state.core.outputs.keyVault.secretName.sshKeyPublic
  key_vault_id = data.azurerm_key_vault.studio.id
}

data azurerm_app_configuration_keys studio {
  configuration_store_id = data.terraform_remote_state.core.outputs.appConfig.id
}

data azurerm_virtual_network studio {
  name                = data.terraform_remote_state.network.outputs.virtualNetwork.default.name
  resource_group_name = data.terraform_remote_state.network.outputs.virtualNetwork.default.resourceGroup.name
}

data azurerm_subnet identity {
  name                 = "Identity"
  resource_group_name  = data.azurerm_virtual_network.studio.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.studio.name
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
  location = data.azurerm_virtual_network.studio.location
  tags = {
    AAA = basename(path.cwd)
  }
}

resource azurerm_resource_group active_directory_client {
  count    = var.activeDirectoryClient.enable ? 1 : 0
  name     = "${azurerm_resource_group.active_directory.name}.Client"
  location = azurerm_resource_group.active_directory.location
  tags = {
    AAA = basename(path.cwd)
  }
}
