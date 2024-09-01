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
    local = {
      source  = "hashicorp/local"
      version = "~>2.5"
    }
    http = {
      source  = "hashicorp/http"
      version = "~>3.4"
    }
    azapi = {
      source = "azure/azapi"
      version = "~>1.15"
    }
  }
  backend azurerm {
    key              = "6.Render.Farm"
    use_azuread_auth = true
  }
}

provider azurerm {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    virtual_machine_scale_set {
      reimage_on_manual_upgrade     = true
      roll_instances_when_required  = true
      scale_to_zero_before_deletion = true
      force_delete                  = false
    }
  }
  subscription_id     = module.global.subscriptionId
  storage_use_azuread = true
}

module global {
  source = "../0.Global.Foundation/cfg"
}

variable resourceGroupName {
  type = string
}

variable activeDirectory {
  type = object({
    enable           = bool
    domainName       = string
    domainServerName = string
    orgUnitPath      = string
    adminUsername    = string
    adminPassword    = string
  })
}

variable existingNetwork {
  type = object({
    enable            = bool
    name              = string
    subnetName        = string
    resourceGroupName = string
  })
}

data azurerm_client_config studio {}

data azurerm_user_assigned_identity studio {
  name                = module.global.managedIdentity.name
  resource_group_name = module.global.resourceGroupName
}

data azurerm_monitor_data_collection_endpoint studio {
  name                = module.global.monitor.name
  resource_group_name = data.terraform_remote_state.global.outputs.monitor.resourceGroupName
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

data azurerm_log_analytics_workspace studio {
  name                = module.global.monitor.name
  resource_group_name = data.terraform_remote_state.global.outputs.monitor.resourceGroupName
}

data azurerm_app_configuration studio {
  name                = module.global.appConfig.name
  resource_group_name = module.global.resourceGroupName
}

data azurerm_app_configuration_keys studio {
  configuration_store_id = data.azurerm_app_configuration.studio.id
}

data terraform_remote_state global {
  backend = "local"
  config = {
    path = "../0.Global.Foundation/terraform.tfstate"
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

data terraform_remote_state image {
  backend = "azurerm"
  config = {
    resource_group_name  = module.global.resourceGroupName
    storage_account_name = module.global.storage.accountName
    container_name       = module.global.storage.containerName.terraformState
    key                  = "2.Image.Builder"
    use_azuread_auth     = true
  }
}

data azurerm_virtual_network studio_region {
  name                = var.existingNetwork.enable ? var.existingNetwork.name : data.terraform_remote_state.network.outputs.virtualNetworks[0].name
  resource_group_name = var.existingNetwork.enable ? var.existingNetwork.resourceGroupName : data.terraform_remote_state.network.outputs.virtualNetworks[0].resourceGroupName
}

data azurerm_virtual_network studio_extended {
  name                = var.existingNetwork.enable ? var.existingNetwork.name : reverse(data.terraform_remote_state.network.outputs.virtualNetworks)[0].name
  resource_group_name = var.existingNetwork.enable ? var.existingNetwork.resourceGroupName : reverse(data.terraform_remote_state.network.outputs.virtualNetworks)[0].resourceGroupName
}

locals {
  fileSystemLinux = [
    for fileSystem in module.global.fileSystem.linux : fileSystem if fileSystem.enable
  ]
  fileSystemWindows = [
    for fileSystem in module.global.fileSystem.windows : fileSystem if fileSystem.enable
  ]
}

resource azurerm_resource_group farm {
  name     = var.resourceGroupName
  location = module.global.resourceLocation.regionName
}
