terraform {
  required_version = ">= 1.8.4"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.109.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>2.52.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~>3.4.3"
    }
    time = {
      source  = "hashicorp/time"
      version = "~>0.11.2"
    }
    azapi = {
      source = "azure/azapi"
      version = "~>1.13.1"
    }
  }
  backend azurerm {
    key = "3.File.Storage.Data"
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
    lake = object({
      paths = list(string)
      storageAccount = object({
        name        = string
        type        = string
        redundancy  = string
        performance = string
      })
    })
    factory = object({
      enable = bool
      name   = string
      encryption = object({
        enable = bool
      })
    })
    analytics = object({
      cosmosDB = object({
        enable     = bool
        schemaType = string
      })
      synapse = object({
        enable = bool
        sqlPools = list(object({
          enable = bool
          name   = string
          size   = string
        }))
        sparkPools = list(object({
          enable  = bool
          name    = string
          version = string
          node = object({
            size       = string
            sizeFamily = string
          })
          cache = object({
            sizePercent = number
          })
          autoScale = object({
            nodeCountMin = number
            nodeCountMax = number
          })
          autoPause = object({
            idleMinutes = number
          })
        }))
      })
      databricks = object({
        enable = bool
        serverless = object({
          enable = bool
        })
        workspace = object({
          tier = string
        })
        storageAccount = object({
          name = string
          type = string
        })
      })
      stream = object({
        enable = bool
        cluster = object({
          name = string
          size = number
        })
      })
      workspace = object({
        name = string
        adminLogin = object({
          userName     = string
          userPassword = string
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

data azurerm_client_config studio {}

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

data azurerm_application_insights studio {
  count               = module.global.monitor.enable ? 1 : 0
  name                = module.global.monitor.name
  resource_group_name = module.global.resourceGroupName
}

data terraform_remote_state ai {
  backend = "azurerm"
  config = {
    resource_group_name  = module.global.resourceGroupName
    storage_account_name = module.global.storage.accountName
    container_name       = module.global.storage.containerName.terraformState
    key                  = "0.Global.Foundation.AI"
  }
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

resource azurerm_resource_group data_integration {
  name     = "${var.resourceGroupName}.Integration"
  location = var.cosmosDB.geoLocations[0].regionName
}
