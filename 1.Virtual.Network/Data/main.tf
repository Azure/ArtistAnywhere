terraform {
  required_version = ">= 1.8.2"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.101.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>2.48.0"
    }
    azapi = {
      source = "azure/azapi"
      version = "~>1.12.1"
    }
    http = {
      source  = "hashicorp/http"
      version = "~>3.4.2"
    }
  }
  backend azurerm {
    key = "1.Virtual.Network.Data"
  }
}

provider azurerm {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

module global {
  source = "../../0.Global.Foundation/config"
}

variable resourceGroupName {
  type = string
}

variable data {
  type = object({
    factory = object({
      enable = bool
      name   = string
      encryption = object({
        enable = bool
      })
    })
    analytics = object({
      enable     = bool
      schemaType = string
      workspace = object({
        name = string
        authentication = object({
          azureADOnly = bool
        })
        adminLogin = object({
          userName     = string
          userPassword = string
        })
        storageAccount = object({
          name        = string
          type        = string
          redundancy  = string
          performance = string
        })
        encryption = object({
          enable = bool
        })
      })
    })
    governance = object({
      enable = bool
      name   = string
    })
  })
}

data http client_address {
  url = "https://api.ipify.org?format=json"
}

data azurerm_user_assigned_identity studio {
  name                = module.global.managedIdentity.name
  resource_group_name = module.global.resourceGroupName
}

data azurerm_key_vault studio {
  count               = module.global.keyVault.enable ? 1 : 0
  name                = module.global.keyVault.name
  resource_group_name = module.global.resourceGroupName
}

data azurerm_key_vault_secret admin_username {
  count        = module.global.keyVault.enable ? 1 : 0
  name         = module.global.keyVault.secretName.adminUsername
  key_vault_id = data.azurerm_key_vault.studio[0].id
}

data azurerm_key_vault_secret admin_password {
  count        = module.global.keyVault.enable ? 1 : 0
  name         = module.global.keyVault.secretName.adminPassword
  key_vault_id = data.azurerm_key_vault.studio[0].id
}

data azurerm_key_vault_secret database_username {
  count        = module.global.keyVault.enable ? 1 : 0
  name         = module.global.keyVault.secretName.databaseUsername
  key_vault_id = data.azurerm_key_vault.studio[0].id
}

data azurerm_key_vault_secret database_password {
  count        = module.global.keyVault.enable ? 1 : 0
  name         = module.global.keyVault.secretName.databasePassword
  key_vault_id = data.azurerm_key_vault.studio[0].id
}

data azurerm_key_vault_key data_encryption {
  count        = module.global.keyVault.enable ? 1 : 0
  name         = module.global.keyVault.keyName.dataEncryption
  key_vault_id = data.azurerm_key_vault.studio[0].id
}

data terraform_remote_state network {
  backend = "azurerm"
  config = {
    resource_group_name  = module.global.resourceGroupName
    storage_account_name = module.global.storage.accountName
    container_name       = module.global.storage.containerName.terraformState
    key                  = "1.Virtual.Network"
  }
}

data azurerm_virtual_network studio_region {
  name                = data.terraform_remote_state.network.outputs.virtualNetworks[0].name
  resource_group_name = data.terraform_remote_state.network.outputs.virtualNetworks[0].resourceGroupName
}

data azurerm_subnet data {
  name                 = "Data"
  resource_group_name  = data.azurerm_virtual_network.studio_region.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.studio_region.name
}

data azurerm_subnet data_cassandra {
  name                 = "DataCassandra"
  resource_group_name  = data.azurerm_virtual_network.studio_region.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.studio_region.name
}

resource azurerm_resource_group data {
  name     = var.resourceGroupName
  location = var.cosmosDB.geoLocations[0].regionName
}

resource azurerm_resource_group data_factory {
  count    = var.data.factory.enable ? 1 : 0
  name     = "${azurerm_resource_group.data.name}.Factory"
  location = azurerm_resource_group.data.location
}

resource azurerm_resource_group data_analytics {
  count    = var.data.analytics.enable ? 1 : 0
  name     = "${azurerm_resource_group.data.name}.Analytics"
  location = azurerm_resource_group.data.location
}

resource azurerm_resource_group data_governance {
  count    = var.data.governance.enable ? 1 : 0
  name     = "${azurerm_resource_group.data.name}.Governance"
  location = azurerm_resource_group.data.location
}
