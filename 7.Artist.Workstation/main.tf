terraform {
  required_version = ">= 1.7.3"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.92.0"
    }
  }
  backend azurerm {
    key = "7.Artist.Workstation"
  }
}

provider azurerm {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    virtual_machine {
      delete_os_disk_on_deletion     = true
      graceful_shutdown              = false
      skip_shutdown_and_force_delete = false
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
    subnetName        = string
    resourceGroupName = string
  })
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

data azurerm_log_analytics_workspace monitor {
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

data azurerm_virtual_network studio {
  name                = var.existingNetwork.enable ? var.existingNetwork.name : data.terraform_remote_state.network.outputs.virtualNetwork.name
  resource_group_name = var.existingNetwork.enable ? var.existingNetwork.resourceGroupName : data.terraform_remote_state.network.outputs.virtualNetwork.resourceGroupName
}

locals {
  rootRegion = {
    name       = var.existingNetwork.enable ? module.global.regionName : data.terraform_remote_state.network.outputs.virtualNetwork.regionName
    nameSuffix = var.existingNetwork.enable ? "" : data.terraform_remote_state.network.outputs.virtualNetwork.nameSuffix
  }
}

resource azurerm_resource_group workstation {
  name     = var.existingNetwork.enable || local.rootRegion.nameSuffix == "" ? var.resourceGroupName : "${var.resourceGroupName}.${local.rootRegion.nameSuffix}"
  location = local.rootRegion.name
}
