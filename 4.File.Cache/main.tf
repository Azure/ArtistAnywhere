terraform {
  required_version = ">= 1.9.4"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.115.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>2.53.1"
    }
    avere = {
      source  = "hashicorp/avere"
      version = "~>1.3.3"
    }
    time = {
      source  = "hashicorp/time"
      version = "~>0.12.0"
    }
  }
  backend azurerm {
    key              = "4.File.Cache"
    use_azuread_auth = true
  }
}

provider azurerm {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    virtual_machine {
      delete_os_disk_on_deletion     = true
      skip_shutdown_and_force_delete = false
      graceful_shutdown              = false
    }
  }
  storage_use_azuread = true
}

module global {
  source = "../0.Global.Foundation/config"
}

variable resourceGroupName {
  type = string
}

variable storageTargets {
  type = list(object({
    enable            = bool
    name              = string
    clientPath        = string
    usageModel        = string
    hostName          = string
    containerName     = string
    resourceGroupName = string
    fileIntervals = object({
      verificationSeconds = number
      writeBackSeconds    = number
    })
    vfxtJunctions = list(object({
      storageExport = string
      storagePath   = string
      clientPath    = string
    }))
  }))
}

variable dnsRecord {
  type = object({
    ttlSeconds = number
  })
}

variable existingNetwork {
  type = object({
    enable            = bool
    name              = string
    subnetName        = string
    regionName        = string
    resourceGroupName = string
    privateDns = object({
      zoneName          = string
      resourceGroupName = string
    })
  })
}

variable subscriptionId {
  type = object({
    terraformState = string
  })
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

data terraform_remote_state network {
  backend = "azurerm"
  config = {
    subscription_id      = local.subscriptionId.terraformState
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
    subscription_id      = local.subscriptionId.terraformState
    resource_group_name  = module.global.resourceGroupName
    storage_account_name = module.global.storage.accountName
    container_name       = module.global.storage.containerName.terraformState
    key                  = "2.Image.Builder"
    use_azuread_auth     = true
  }
}

data terraform_remote_state storage {
  backend = "azurerm"
  config = {
    subscription_id      = local.subscriptionId.terraformState
    resource_group_name  = module.global.resourceGroupName
    storage_account_name = module.global.storage.accountName
    container_name       = module.global.storage.containerName.terraformState
    key                  = "3.File.Storage"
    use_azuread_auth     = true
  }
}

data azurerm_virtual_network studio_region {
  name                = var.existingNetwork.enable ? var.existingNetwork.name : data.terraform_remote_state.network.outputs.virtualNetworks[0].name
  resource_group_name = var.existingNetwork.enable ? var.existingNetwork.resourceGroupName : data.terraform_remote_state.network.outputs.virtualNetworks[0].resourceGroupName
}

data azurerm_subnet cache {
  name                 = var.existingNetwork.enable ? var.existingNetwork.subnetName : "Cache"
  resource_group_name  = data.azurerm_virtual_network.studio_region.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.studio_region.name
}

data azurerm_private_dns_zone studio {
  name                = var.existingNetwork.enable ? var.existingNetwork.privateDns.zoneName : data.terraform_remote_state.network.outputs.privateDns.zoneName
  resource_group_name = var.existingNetwork.enable ? var.existingNetwork.privateDns.resourceGroupName : data.terraform_remote_state.network.outputs.privateDns.resourceGroupName
}

locals {
  subscriptionId = {
    terraformState = var.subscriptionId.terraformState != "" ? var.subscriptionId.terraformState : data.azurerm_client_config.studio.subscription_id
  }
  blobStorageAccountNfs = try(data.terraform_remote_state.storage.outputs.blobStorageAccountNfs, {})
}

resource azurerm_resource_group cache {
  name     = var.resourceGroupName
  location = var.existingNetwork.enable ? var.existingNetwork.regionName : module.global.resourceLocation.regionName
}
