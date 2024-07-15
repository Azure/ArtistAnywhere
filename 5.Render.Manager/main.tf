terraform {
  required_version = ">= 1.9.2"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.112.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>2.53.1"
    }
  }
  backend azurerm {
    key = "5.Render.Manager"
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
}

module global {
  source = "../0.Global.Foundation/config"
}

variable resourceGroupName {
  type = string
}

variable dnsRecord {
  type = object({
    name       = string
    ttlSeconds = number
  })
}

variable activeDirectory {
  type = object({
    enable     = bool
    domainName = string
  })
}

variable existingNetwork {
  type = object({
    enable            = bool
    name              = string
    subnetName        = string
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
    computeGallery = string
  })
}

data azurerm_client_config studio {}

data azurerm_user_assigned_identity studio {
  name                = module.global.managedIdentity.name
  resource_group_name = module.global.resourceGroupName
}

data azurerm_monitor_data_collection_endpoint studio {
  count               = module.global.monitor.enable ? 1 : 0
  name                = module.global.monitor.name
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
    subscription_id      = local.subscriptionId.terraformState
    resource_group_name  = module.global.resourceGroupName
    storage_account_name = module.global.storage.accountName
    container_name       = module.global.storage.containerName.terraformState
    key                  = "1.Virtual.Network${lower(terraform.workspace) == "shared" ? "env:shared" : ""}"
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
  }
}

data azurerm_virtual_network studio_region {
  name                = var.existingNetwork.enable ? var.existingNetwork.name : data.terraform_remote_state.network.outputs.virtualNetworks[0].name
  resource_group_name = var.existingNetwork.enable ? var.existingNetwork.resourceGroupName : data.terraform_remote_state.network.outputs.virtualNetworks[0].resourceGroupName
}

data azurerm_virtual_network studio_edge {
  name                = var.existingNetwork.enable ? var.existingNetwork.name : reverse(data.terraform_remote_state.network.outputs.virtualNetworks)[0].name
  resource_group_name = var.existingNetwork.enable ? var.existingNetwork.resourceGroupName : reverse(data.terraform_remote_state.network.outputs.virtualNetworks)[0].resourceGroupName
}

data azurerm_private_dns_zone studio {
  name                = var.existingNetwork.enable ? var.existingNetwork.privateDns.zoneName : data.terraform_remote_state.network.outputs.privateDns.zoneName
  resource_group_name = var.existingNetwork.enable ? var.existingNetwork.privateDns.resourceGroupName : data.terraform_remote_state.network.outputs.privateDns.resourceGroupName
}

locals {
  subscriptionId = {
    terraformState = var.subscriptionId.terraformState != "" ? var.subscriptionId.terraformState : data.azurerm_client_config.studio.subscription_id
    computeGallery = var.subscriptionId.computeGallery != "" ? var.subscriptionId.computeGallery : data.azurerm_client_config.studio.subscription_id
  }
}

resource azurerm_resource_group scheduler {
  name     = var.resourceGroupName
  location = module.global.resourceLocation.regionName
}

resource azurerm_private_dns_a_record scheduler {
  for_each = {
    for virtualMachine in var.virtualMachines : virtualMachine.name => virtualMachine if virtualMachine.enable
  }
  name                = var.dnsRecord.name
  resource_group_name = data.azurerm_private_dns_zone.studio.resource_group_name
  zone_name           = data.azurerm_private_dns_zone.studio.name
  ttl                 = var.dnsRecord.ttlSeconds
  records = [
    azurerm_network_interface.scheduler[each.value.name].private_ip_address
  ]
}
