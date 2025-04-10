terraform {
  required_version = ">=1.11.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.26.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>3.3.0"
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

variable extendedZone {
  type = object({
    enable   = bool
    name     = string
    location = string
  })
}

variable dnsRecord {
  type = object({
    name       = string
    ttlSeconds = number
  })
}

variable virtualNetwork {
  type = object({
    enable            = bool
    name              = string
    subnetName        = string
    resourceGroupName = string
    privateDNS = object({
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

data terraform_remote_state core {
  backend = "local"
  config = {
    path = "../0.Core.Foundation/terraform.tfstate"
  }
}

data terraform_remote_state network {
  backend = "azurerm"
  config = {
    subscription_id      = data.terraform_remote_state.core.outputs.subscriptionId
    resource_group_name  = data.terraform_remote_state.core.outputs.resourceGroup.name
    storage_account_name = data.terraform_remote_state.core.outputs.storage.account.name
    container_name       = data.terraform_remote_state.core.outputs.storage.containerName.terraformState
    key                  = "1.Virtual.Network"
    use_azuread_auth     = true
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
  name                = var.virtualNetwork.enable ? var.virtualNetwork.name : data.terraform_remote_state.network.outputs.virtualNetwork.default.name
  resource_group_name = var.virtualNetwork.enable ? var.virtualNetwork.resourceGroupName : data.terraform_remote_state.network.outputs.virtualNetwork.default.resourceGroup.name
}

data azurerm_virtual_network studio_extended {
  count               = var.extendedZone.enable ? 1 : 0
  name                = var.virtualNetwork.enable ? var.virtualNetwork.name : data.terraform_remote_state.network.outputs.virtualNetwork.extended.name
  resource_group_name = var.virtualNetwork.enable ? var.virtualNetwork.resourceGroupName : data.terraform_remote_state.network.outputs.virtualNetwork.extended.resourceGroup.name
}

data azurerm_private_dns_zone studio {
  name                = var.virtualNetwork.enable ? var.virtualNetwork.privateDNS.zoneName : data.terraform_remote_state.network.outputs.privateDNS.zone.name
  resource_group_name = var.virtualNetwork.enable ? var.virtualNetwork.privateDNS.resourceGroupName : data.terraform_remote_state.network.outputs.privateDNS.zone.resourceGroup.name
}

resource azurerm_resource_group job_scheduler {
  name     = var.resourceGroupName
  location = data.terraform_remote_state.core.outputs.defaultLocation
  tags = {
    AAA = basename(path.cwd)
  }
}

resource azurerm_private_dns_a_record job_scheduler {
  for_each = {
    for virtualMachine in var.virtualMachines : virtualMachine.name => virtualMachine if virtualMachine.enable
  }
  name                = lower(var.dnsRecord.name)
  resource_group_name = data.azurerm_private_dns_zone.studio.resource_group_name
  zone_name           = data.azurerm_private_dns_zone.studio.name
  ttl                 = var.dnsRecord.ttlSeconds
  records = [
    azurerm_network_interface.job_scheduler[each.value.name].private_ip_address
  ]
}
