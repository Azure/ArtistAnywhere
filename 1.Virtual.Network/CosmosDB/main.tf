terraform {
  required_version = ">= 1.7.3"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.96.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>2.47.0"
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
    key = "1.Virtual.Network.CosmosDB"
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

data terraform_remote_state network {
  backend = "azurerm"
  config = {
    resource_group_name  = module.global.resourceGroupName
    storage_account_name = module.global.rootStorage.accountName
    container_name       = module.global.rootStorage.containerName.terraformState
    key                  = "1.Virtual.Network"
  }
}

data azurerm_virtual_network studio {
  name                = local.writeVirtualNetwork.name
  resource_group_name = local.writeVirtualNetwork.resourceGroupName
}

data azurerm_subnet data {
  name                 = "Data"
  resource_group_name  = data.azurerm_virtual_network.studio.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.studio.name
}

data azurerm_subnet data_cassandra {
  name                 = "DataCassandra"
  resource_group_name  = data.azurerm_virtual_network.studio.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.studio.name
}

locals {
  writeGeoLocation = one([
    for geoLocation in var.cosmosDB.geoLocations : geoLocation if geoLocation.failover.priority == 0
  ])
  writeVirtualNetwork = one([
    for virtualNetwork in data.terraform_remote_state.network.outputs.virtualNetworks : virtualNetwork if virtualNetwork.regionName == local.writeGeoLocation.regionName
  ])
}

resource azurerm_resource_group database {
  name     = var.resourceGroupName
  location = var.cosmosDB.geoLocations[0].regionName
}
