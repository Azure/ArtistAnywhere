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
    enable             = bool
    name               = string
    subnetName         = string
    resourceGroupName  = string
    privateDnsZoneName = string
  })
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

data azurerm_virtual_network studio {
  name                = var.existingNetwork.enable ? var.existingNetwork.name : data.terraform_remote_state.network.outputs.virtualNetwork.name
  resource_group_name = var.existingNetwork.enable ? var.existingNetwork.resourceGroupName : data.terraform_remote_state.network.outputs.virtualNetwork.resourceGroupName
}

data azurerm_private_dns_zone studio {
  name                = var.existingNetwork.enable ? var.existingNetwork.privateDnsZoneName : data.terraform_remote_state.network.outputs.privateDns.name
  resource_group_name = var.existingNetwork.enable ? var.existingNetwork.resourceGroupName : data.terraform_remote_state.network.outputs.privateDns.resourceGroupName
}

locals {
  rootRegion = {
    name       = var.existingNetwork.enable ? module.global.resourceLocation.region : data.terraform_remote_state.network.outputs.virtualNetwork.regionName
    nameSuffix = var.existingNetwork.enable ? "" : data.terraform_remote_state.network.outputs.virtualNetwork.nameSuffix
  }
  edgeZone = module.global.resourceLocation.edgeZone != "" ? module.global.resourceLocation.edgeZone : null
}

resource azurerm_resource_group scheduler {
  name     = var.existingNetwork.enable || local.rootRegion.nameSuffix == "" ? var.resourceGroupName : "${var.resourceGroupName}.${local.rootRegion.nameSuffix}"
  location = local.rootRegion.name
}

resource azurerm_resource_group scheduler_edge {
  count    = module.global.resourceLocation.edgeZone != "" ? 1 : 0
  name     = "${azurerm_resource_group.scheduler.name}.Edge"
  location = local.rootRegion.name
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
