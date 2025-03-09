terraform {
  required_version = ">=1.11.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.22.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>3.1.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~>3.4.0"
    }
  }
  backend azurerm {
    key              = "5.Job.Scheduler.SQL"
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

variable existingNetwork {
  type = object({
    enable            = bool
    name              = string
    subnetName        = string
    resourceGroupName = string
  })
}

data http client_address {
  url = "https://api.ipify.org?format=json"
}

data azurerm_client_config current {}

data azuread_user current {
  object_id = data.azurerm_client_config.current.object_id
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

data azurerm_key_vault_key data_encryption {
  name         = module.core.keyVault.keyName.dataEncryption
  key_vault_id = data.azurerm_key_vault.studio.id
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

data azurerm_virtual_network studio {
  name                = var.existingNetwork.enable ? var.existingNetwork.name : data.terraform_remote_state.network.outputs.virtualNetworks[0].name
  resource_group_name = var.existingNetwork.enable ? var.existingNetwork.resourceGroupName : data.terraform_remote_state.network.outputs.virtualNetworks[0].resourceGroupName
}

data azurerm_subnet data {
  name                 = var.existingNetwork.enable ? var.existingNetwork.subnetName : "Data"
  resource_group_name  = data.azurerm_virtual_network.studio.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.studio.name
}

data azurerm_subnet data_mysql {
  count                = var.mySQL.enable && var.mySQL.delegatedSubnet.enable ? 1 : 0
  name                 = var.existingNetwork.enable ? var.existingNetwork.subnetName : "DataMySQL"
  resource_group_name  = data.azurerm_virtual_network.studio.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.studio.name
}

data azurerm_subnet data_postgresql {
  count                = var.postgreSQL.enable && var.postgreSQL.delegatedSubnet.enable ? 1 : 0
  name                 = var.existingNetwork.enable ? var.existingNetwork.subnetName : "DataPostgreSQL"
  resource_group_name  = data.azurerm_virtual_network.studio.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.studio.name
}

resource azurerm_resource_group job_scheduler_mysql {
  count    = var.mySQL.enable ? 1 : 0
  name     = "${var.resourceGroupName}.MySQL"
  location = module.core.resourceLocation.regionName
  tags = {
    AAA = "${basename(dirname(path.cwd))}.${basename(path.cwd)}"
  }
}

resource azurerm_resource_group job_scheduler_postgresql {
  count    = var.postgreSQL.enable ? 1 : 0
  name     = "${var.resourceGroupName}.PostgreSQL"
  location = module.core.resourceLocation.regionName
  tags = {
    AAA = "${basename(dirname(path.cwd))}.${basename(path.cwd)}"
  }
}
