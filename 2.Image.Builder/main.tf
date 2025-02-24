terraform {
  required_version = ">=1.10.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.20.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~>3.4.0"
    }
    azapi = {
      source = "azure/azapi"
      version = "~>2.2.0"
    }
  }
  backend azurerm {
    key              = "2.Image.Builder"
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
  source = "../0.Global.Foundation/config"
}

variable resourceGroupName {
  type = string
}

data http client_address {
  url = "https://api.ipify.org?format=json"
}

data azurerm_client_config current {}

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

data azurerm_key_vault_secret ssh_key_public {
  name         = module.global.keyVault.secretName.sshKeyPublic
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
  name                = data.terraform_remote_state.network.outputs.virtualNetworks[0].name
  resource_group_name = data.terraform_remote_state.network.outputs.virtualNetworks[0].resourceGroupName
}

data azurerm_subnet compute {
  name                 = "Compute"
  resource_group_name  = data.azurerm_virtual_network.studio.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.studio.name
}

data azurerm_resource_group network {
  name = data.azurerm_virtual_network.studio.resource_group_name
}

locals {
  regionNames = distinct([
    for virtualNetwork in data.terraform_remote_state.network.outputs.virtualNetworks : virtualNetwork.regionName
  ])
}

resource azurerm_resource_group image_builder {
  name     = "${var.resourceGroupName}.Builder"
  location = module.global.resourceLocation.regionName
  tags = {
    AAA = basename(path.cwd)
  }
}

resource azurerm_resource_group image_gallery {
  name     = "${var.resourceGroupName}.Gallery"
  location = module.global.resourceLocation.regionName
  tags = {
    AAA = basename(path.cwd)
  }
}

resource azurerm_resource_group image_registry {
  count    = var.containerRegistry.enable ? 1 : 0
  name     = "${var.resourceGroupName}.Registry"
  location = module.global.resourceLocation.regionName
  tags = {
    AAA = basename(path.cwd)
  }
}
