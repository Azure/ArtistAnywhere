terraform {
  required_version = ">=1.9.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>2.53"
    }
    http = {
      source  = "hashicorp/http"
      version = "~>3.4"
    }
    time = {
      source  = "hashicorp/time"
      version = "~>0.12"
    }
    azapi = {
      source = "azure/azapi"
      version = "~>1.15"
    }
  }
  backend azurerm {
    key              = "3.File.Storage.Data"
    use_azuread_auth = true
  }
}

provider azurerm {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    postgresql_flexible_server {
      restart_server_on_configuration_value_change = true
    }
  }
  subscription_id     = module.global.subscriptionId
  storage_use_azuread = true
}

module global {
  source = "../../0.Global.Foundation/cfg"
}

variable resourceGroupName {
  type = string
}

variable data {
  type = object({
    lake = object({
      storageAccount = object({
        name        = string
        type        = string
        redundancy  = string
        performance = string
      })
      fileSystem = object({
        name  = string
        paths = list(string)
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
          backup = object({
            storageAccount = object({
              type = string
            })
            geoPolicy = object({
              enable = bool
            })
          })
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
    integration = object({
      enable = bool
      name   = string
      tier   = string
      encryption = object({
        enable = bool
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

data azurerm_key_vault_secret service_username {
  name         = module.global.keyVault.secretName.serviceUsername
  key_vault_id = data.azurerm_key_vault.studio.id
}

data azurerm_key_vault_secret service_password {
  name         = module.global.keyVault.secretName.servicePassword
  key_vault_id = data.azurerm_key_vault.studio.id
}

data azurerm_key_vault_key data_encryption {
  name         = module.global.keyVault.keyName.dataEncryption
  key_vault_id = data.azurerm_key_vault.studio.id
}

data azurerm_application_insights studio {
  name                = module.global.monitor.name
  resource_group_name = data.terraform_remote_state.global.outputs.monitor.resourceGroupName
}

data terraform_remote_state global {
  backend = "local"
  config = {
    path = "../../0.Global.Foundation/terraform.tfstate"
  }
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

data azurerm_virtual_network studio_region {
  name                = data.terraform_remote_state.network.outputs.virtualNetworks[local.cosmosDBNetworkIndex].name
  resource_group_name = data.terraform_remote_state.network.outputs.virtualNetworks[local.cosmosDBNetworkIndex].resourceGroupName
}

data azurerm_subnet data {
  name                 = "Data"
  resource_group_name  = data.azurerm_virtual_network.studio_region.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.studio_region.name
}

data azurerm_subnet data_postgre_sql {
  name                 = "DataPostgreSQL"
  resource_group_name  = data.azurerm_virtual_network.studio_region.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.studio_region.name
}

data azurerm_subnet data_cassandra {
  name                 = "DataCassandra"
  resource_group_name  = data.azurerm_virtual_network.studio_region.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.studio_region.name
}

locals {
  cosmosDBNetworkIndex = [
    for i in range(length(data.terraform_remote_state.network.outputs.virtualNetworks)) : i if data.terraform_remote_state.network.outputs.virtualNetworks[i].regionName == var.cosmosDB.geoLocations[0].regionName
  ][0]
}

resource azurerm_resource_group data {
  name     = var.resourceGroupName
  location = var.cosmosDB.geoLocations[0].regionName
}

resource azurerm_resource_group data_integration {
  count    = var.data.integration.enable ? 1 : 0
  name     = "${var.resourceGroupName}.Integration"
  location = var.cosmosDB.geoLocations[0].regionName
}
