terraform {
  required_version = ">= 1.7.3"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.97.1"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>2.47.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~>3.4.2"
    }
  }
  backend azurerm {
    key = "6.Render.Farm"
  }
}

provider azurerm {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    virtual_machine_scale_set {
      force_delete                  = false
      roll_instances_when_required  = true
      scale_to_zero_before_deletion = true
    }
    cognitive_account {
      purge_soft_delete_on_destroy = true
    }
  }
}

module global {
  source = "../0.Global.Foundation/config"
}

variable resourceGroupName {
  type = string
}

variable fileSystems {
  type = object({
    linux = list(object({
      enable   = bool
      iaasOnly = bool
      mount = object({
        type    = string
        path    = string
        source  = string
        options = string
      })
    }))
    windows = list(object({
      enable   = bool
      iaasOnly = bool
      mount = object({
        type    = string
        path    = string
        source  = string
        options = string
      })
    }))
  })
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
    subnetNameFarm    = string
    subnetNameAI      = string
    resourceGroupName = string
  })
}

variable existingStorage {
  type = object({
    enable            = bool
    name              = string
    resourceGroupName = string
    fileShareName     = string
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

data azurerm_monitor_data_collection_endpoint studio {
  count               = module.global.monitor.enable ? 1 : 0
  name                = module.global.monitor.name
  resource_group_name = module.global.resourceGroupName
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

data terraform_remote_state image {
  backend = "azurerm"
  config = {
    resource_group_name  = module.global.resourceGroupName
    storage_account_name = module.global.rootStorage.accountName
    container_name       = module.global.rootStorage.containerName.terraformState
    key                  = "2.Image.Builder"
  }
}


data terraform_remote_state storage {
  backend = "azurerm"
  config = {
    resource_group_name  = module.global.resourceGroupName
    storage_account_name = module.global.rootStorage.accountName
    container_name       = module.global.rootStorage.containerName.terraformState
    key                  = "3.File.Storage"
  }
}

data azurerm_virtual_network studio {
  name                = var.existingNetwork.enable ? var.existingNetwork.name : data.terraform_remote_state.network.outputs.virtualNetwork.name
  resource_group_name = var.existingNetwork.enable ? var.existingNetwork.resourceGroupName : data.terraform_remote_state.network.outputs.virtualNetwork.resourceGroupName
}

data azurerm_storage_account studio {
  name                = var.existingStorage.enable ? var.existingStorage.name : data.terraform_remote_state.storage.outputs.blobStorageAccount.name
  resource_group_name = var.existingStorage.enable ? var.existingStorage.resourceGroupName : data.terraform_remote_state.storage.outputs.blobStorageAccount.resourceGroupName
}

locals {
  rootRegion = {
    name       = var.existingNetwork.enable ? module.global.resourceLocation.region : data.terraform_remote_state.network.outputs.virtualNetwork.regionName
    nameSuffix = var.existingNetwork.enable ? "" : data.terraform_remote_state.network.outputs.virtualNetwork.nameSuffix
  }
  edgeZone = module.global.resourceLocation.edgeZone != "" ? module.global.resourceLocation.edgeZone : null
}

resource azurerm_resource_group farm {
  name     = var.existingNetwork.enable || local.rootRegion.nameSuffix == "" ? var.resourceGroupName : "${var.resourceGroupName}.${local.rootRegion.nameSuffix}"
  location = local.rootRegion.name
}

resource azurerm_resource_group farm_edge {
  count    = module.global.resourceLocation.edgeZone != "" ? 1 : 0
  name     = "${azurerm_resource_group.farm.name}.Edge"
  location = local.rootRegion.name
}
