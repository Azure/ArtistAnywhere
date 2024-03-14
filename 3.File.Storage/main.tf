terraform {
  required_version = ">= 1.7.3"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.95.0"
    }
    azapi = {
      source = "azure/azapi"
      version = "~>1.12.1"
    }
    http = {
      source  = "hashicorp/http"
      version = "~>3.4.2"
    }
    local = {
      source  = "hashicorp/local"
      version = "~>2.4.1"
    }
  }
  backend azurerm {
    key = "3.File.Storage"
  }
}

provider azurerm {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    managed_disk {
      expand_without_downtime = true
    }
    virtual_machine {
      delete_os_disk_on_deletion     = true
      graceful_shutdown              = false
      skip_shutdown_and_force_delete = false
    }
    virtual_machine_scale_set {
      force_delete                  = false
      roll_instances_when_required  = true
      scale_to_zero_before_deletion = true
    }
  }
}

module global {
  source = "../0.Global.Foundation/config"
}

variable resourceGroupName {
  type = string
}

variable fileLoadSource {
  type = object({
    enable        = bool
    accountName   = string
    accountKey    = string
    containerName = string
    blobName      = string
  })
}

variable existingNetwork {
  type = object({
    enable             = bool
    name               = string
    subnetName         = string
    resourceGroupName  = string
    privateDnsZoneName = string
    serviceEndpointSubnets = list(object({
      name               = string
      virtualNetworkName = string
    }))
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

data terraform_remote_state network {
  backend = "azurerm"
  config = {
    resource_group_name  = module.global.resourceGroupName
    storage_account_name = module.global.rootStorage.accountName
    container_name       = module.global.rootStorage.containerName.terraformState
    key                  = "1.Virtual.Network"
  }
}

data azurerm_resource_group network {
  name = data.azurerm_virtual_network.studio.resource_group_name
}

data azurerm_resource_group dns {
  name = data.terraform_remote_state.network.outputs.privateDns.resourceGroupName
}

data azurerm_virtual_network studio {
  name                = var.existingNetwork.enable ? var.existingNetwork.name : data.terraform_remote_state.network.outputs.virtualNetwork.name
  resource_group_name = var.existingNetwork.enable ? var.existingNetwork.resourceGroupName : data.terraform_remote_state.network.outputs.virtualNetwork.resourceGroupName
}

data azurerm_subnet storage {
  name                 = var.existingNetwork.enable ? var.existingNetwork.subnetName : "Storage"
  resource_group_name  = data.azurerm_virtual_network.studio.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.studio.name
}

data azurerm_private_dns_zone studio {
  name                = var.existingNetwork.enable ? var.existingNetwork.privateDnsZoneName : data.terraform_remote_state.network.outputs.privateDns.name
  resource_group_name = var.existingNetwork.enable ? var.existingNetwork.resourceGroupName : data.terraform_remote_state.network.outputs.privateDns.resourceGroupName
}

locals {
  rootRegion = {
    name       = var.existingNetwork.enable ? module.global.primaryRegion.name : data.terraform_remote_state.network.outputs.virtualNetwork.regionName
    nameSuffix = var.existingNetwork.enable ? "" : data.terraform_remote_state.network.outputs.virtualNetwork.nameSuffix
  }
}

resource azurerm_resource_group storage {
  name     = var.existingNetwork.enable || local.rootRegion.nameSuffix == "" ? var.resourceGroupName : "${var.resourceGroupName}.${local.rootRegion.nameSuffix}"
  location = local.rootRegion.name
}
