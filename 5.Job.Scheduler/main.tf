terraform {
  required_version = ">=1.10.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.20.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>3.1.0"
    }
  }
  backend azurerm {
    key              = "5.Job.Scheduler"
    use_azuread_auth = true
  }
}

provider azurerm {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    virtual_machine {
      delete_os_disk_on_deletion            = true
      detach_implicit_data_disk_on_deletion = false
      skip_shutdown_and_force_delete        = false
      graceful_shutdown                     = false
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

variable dnsRecord {
  type = object({
    name       = string
    ttlSeconds = number
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

data azurerm_virtual_network studio {
  name                = var.existingNetwork.enable ? var.existingNetwork.name : data.terraform_remote_state.network.outputs.virtualNetworks[0].name
  resource_group_name = var.existingNetwork.enable ? var.existingNetwork.resourceGroupName : data.terraform_remote_state.network.outputs.virtualNetworks[0].resourceGroupName
}

data azurerm_virtual_network studio_extended {
  name                = var.existingNetwork.enable ? var.existingNetwork.name : reverse(data.terraform_remote_state.network.outputs.virtualNetworks)[0].name
  resource_group_name = var.existingNetwork.enable ? var.existingNetwork.resourceGroupName : reverse(data.terraform_remote_state.network.outputs.virtualNetworks)[0].resourceGroupName
}

data azurerm_private_dns_zone studio {
  name                = var.existingNetwork.enable ? var.existingNetwork.privateDns.zoneName : data.terraform_remote_state.network.outputs.privateDns.zoneName
  resource_group_name = var.existingNetwork.enable ? var.existingNetwork.privateDns.resourceGroupName : data.terraform_remote_state.network.outputs.privateDns.resourceGroupName
}

resource azurerm_resource_group job_scheduler {
  name     = var.resourceGroupName
  location = module.global.resourceLocation.regionName
  tags = {
    AAA = basename(path.cwd)
  }
}

resource azurerm_private_dns_a_record job_scheduler {
  for_each = {
    for virtualMachine in var.virtualMachines : virtualMachine.name => virtualMachine if virtualMachine.enable
  }
  name                = var.dnsRecord.name
  resource_group_name = data.azurerm_private_dns_zone.studio.resource_group_name
  zone_name           = data.azurerm_private_dns_zone.studio.name
  ttl                 = var.dnsRecord.ttlSeconds
  records = [
    azurerm_network_interface.job_scheduler[each.value.name].private_ip_address
  ]
}
