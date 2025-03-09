terraform {
  required_version = ">=1.11.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.22.0"
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
  }
  subscription_id     = data.terraform_remote_state.core.outputs.subscription.id
  storage_use_azuread = true
}

module core {
  source = "../0.Core.Foundation/config"
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

variable activeDirectory {
  type = object({
    enable = bool
    domain = object({
      name = string
    })
    machine = object({
      name = string
      adminLogin = object({
        userName     = string
        userPassword = string
      })
    })
  })
}

data azurerm_subscription current {}

data azurerm_user_assigned_identity studio {
  name                = module.core.managedIdentity.name
  resource_group_name = data.terraform_remote_state.core.outputs.monitor.resourceGroupName
}

data azurerm_monitor_data_collection_endpoint studio {
  name                = module.core.monitor.name
  resource_group_name = data.terraform_remote_state.core.outputs.monitor.resourceGroupName
}

data azurerm_key_vault studio {
  name                = module.core.keyVault.name
  resource_group_name = data.terraform_remote_state.core.outputs.monitor.resourceGroupName
}

data azurerm_key_vault_secret admin_username {
  name         = module.core.keyVault.secretName.adminUsername
  key_vault_id = data.azurerm_key_vault.studio.id
}

data azurerm_key_vault_secret admin_password {
  name         = module.core.keyVault.secretName.adminPassword
  key_vault_id = data.azurerm_key_vault.studio.id
}

data azurerm_key_vault_secret ssh_key_public {
  name         = module.core.keyVault.secretName.sshKeyPublic
  key_vault_id = data.azurerm_key_vault.studio.id
}

data azurerm_log_analytics_workspace studio {
  name                = module.core.monitor.name
  resource_group_name = data.terraform_remote_state.core.outputs.monitor.resourceGroupName
}

data terraform_remote_state core {
  backend = "local"
  config = {
    path = "../0.Core.Foundation/terraform.tfstate"
  }
}

data terraform_remote_state network {
  backend = "azurerm"
  config = {
    subscription_id      = data.terraform_remote_state.core.outputs.subscription.id
    resource_group_name  = data.terraform_remote_state.core.outputs.resourceGroup.name
    storage_account_name = data.terraform_remote_state.core.outputs.storage.account.name
    container_name       = data.terraform_remote_state.core.outputs.storage.containerName.terraformState
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
  location = module.core.resourceLocation.regionName
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
