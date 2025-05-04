terraform {
  required_version = ">=1.11.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.27.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>3.3.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~>2.3.0"
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
  subscription_id     = data.terraform_remote_state.core.outputs.subscriptionId
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

variable virtualNetwork {
  type = object({
    name              = string
    subnetName        = string
    resourceGroupName = string
  })
}

variable virtualNetworkExtended {
  type = object({
    enable            = bool
    name              = string
    subnetName        = string
    resourceGroupName = string
  })
}

variable privateDNS {
  type = object({
    zoneName          = string
    resourceGroupName = string
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

data terraform_remote_state core {
  backend = "local"
  config = {
    path = "../0.Core.Foundation/terraform.tfstate"
  }
}

data azurerm_user_assigned_identity studio {
  name                = data.terraform_remote_state.core.outputs.managedIdentity.name
  resource_group_name = data.terraform_remote_state.core.outputs.resourceGroup.name
}

data azurerm_key_vault studio {
  name                = data.terraform_remote_state.core.outputs.keyVault.name
  resource_group_name = data.terraform_remote_state.core.outputs.resourceGroup.name
}

data azurerm_key_vault_secret admin_username {
  name         = data.terraform_remote_state.core.outputs.keyVault.secretName.adminUsername
  key_vault_id = data.azurerm_key_vault.studio.id
}

data azurerm_key_vault_secret admin_password {
  name         = data.terraform_remote_state.core.outputs.keyVault.secretName.adminPassword
  key_vault_id = data.azurerm_key_vault.studio.id
}

data azurerm_key_vault_secret ssh_key_public {
  name         = data.terraform_remote_state.core.outputs.keyVault.secretName.sshKeyPublic
  key_vault_id = data.azurerm_key_vault.studio.id
}

data azurerm_app_configuration_keys studio {
  configuration_store_id = data.terraform_remote_state.core.outputs.appConfig.id
}

data azurerm_virtual_network studio {
  name                = var.virtualNetwork.name
  resource_group_name = var.virtualNetwork.resourceGroupName
}

data azurerm_virtual_network studio_extended {
  count               = var.virtualNetworkExtended.enable ? 1 : 0
  name                = var.virtualNetworkExtended.name
  resource_group_name = var.virtualNetworkExtended.resourceGroupName
}

resource azurerm_resource_group job_scheduler {
  name     = var.resourceGroupName
  location = data.azurerm_virtual_network.studio.location
  tags = {
    AAA = basename(path.cwd)
  }
}

resource azurerm_private_dns_a_record job_scheduler {
  for_each = {
    for virtualMachine in var.virtualMachines : virtualMachine.name => virtualMachine if virtualMachine.enable
  }
  name                = lower(var.dnsRecord.name)
  resource_group_name = var.privateDNS.resourceGroupName
  zone_name           = var.privateDNS.zoneName
  ttl                 = var.dnsRecord.ttlSeconds
  records = [
    azurerm_network_interface.job_scheduler[each.value.name].private_ip_address
  ]
}
