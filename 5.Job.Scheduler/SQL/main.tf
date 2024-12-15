terraform {
  required_version = ">=1.10.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.14.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>3.0.0"
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
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id     = module.global.subscriptionId
  storage_use_azuread = true
}

module global {
  source = "../../0.Global.Foundation/config"
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
  name                = module.global.managedIdentity.name
  resource_group_name = module.global.resourceGroupName
}

data azurerm_key_vault studio {
  name                = module.global.keyVault.name
  resource_group_name = module.global.resourceGroupName
}

data azurerm_key_vault_secret admin_username {
  name         = module.global.keyVault.secretName.adminUsername
  key_vault_id = data.azurerm_key_vault.studio.id
}

data azurerm_key_vault_secret admin_password {
  name         = module.global.keyVault.secretName.adminPassword
  key_vault_id = data.azurerm_key_vault.studio.id
}

data azurerm_key_vault_key data_encryption {
  name         = module.global.keyVault.keyName.dataEncryption
  key_vault_id = data.azurerm_key_vault.studio.id
}

data terraform_remote_state network {
  backend = "azurerm"
  config = {
    resource_group_name  = module.global.resourceGroupName
    storage_account_name = module.global.storage.accountName
    container_name       = module.global.storage.containerName.terraformState
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
  location = module.global.resourceLocation.regionName
  tags = {
    AAA = "${basename(dirname(path.cwd))}.${basename(path.cwd)}"
  }
}

resource azurerm_resource_group job_scheduler_postgresql {
  count    = var.postgreSQL.enable ? 1 : 0
  name     = "${var.resourceGroupName}.PostgreSQL"
  location = module.global.resourceLocation.regionName
  tags = {
    AAA = "${basename(dirname(path.cwd))}.${basename(path.cwd)}"
  }
}
