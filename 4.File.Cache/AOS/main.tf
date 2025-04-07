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
    avere = {
      source  = "hashicorp/avere"
      version = "~>1.3.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~>0.13.0"
    }
  }
  backend azurerm {
    key              = "4.File.Cache.AOS"
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
  source = "../../0.Core.Foundation/config"
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

data azurerm_user_assigned_identity studio {
  name                = module.core.managedIdentity.name
  resource_group_name = data.terraform_remote_state.core.outputs.resourceGroup.name
}

data azurerm_key_vault studio {
  name                = module.core.keyVault.name
  resource_group_name = data.terraform_remote_state.core.outputs.resourceGroup.name
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

data terraform_remote_state core {
  backend = "local"
  config = {
    path = "../../0.Core.Foundation/terraform.tfstate"
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
  name                = var.virtualNetwork.enable ? var.virtualNetwork.name : data.terraform_remote_state.network.outputs.virtualNetwork.default.name
  resource_group_name = var.virtualNetwork.enable ? var.virtualNetwork.resourceGroupName : data.terraform_remote_state.network.outputs.virtualNetwork.default.resourceGroup.name
}

data azurerm_subnet cache {
  name                 = var.virtualNetwork.enable ? var.virtualNetwork.subnetName : "Cache"
  resource_group_name  = data.azurerm_virtual_network.studio.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.studio.name
}

data azurerm_private_dns_zone studio {
  name                = var.virtualNetwork.enable ? var.virtualNetwork.privateDNS.zoneName : data.terraform_remote_state.network.outputs.privateDNS.zone.name
  resource_group_name = var.virtualNetwork.enable ? var.virtualNetwork.privateDNS.resourceGroupName : data.terraform_remote_state.network.outputs.privateDNS.zone.resourceGroup.name
}

resource azurerm_resource_group cache {
  name     = var.resourceGroupName
  location = var.virtualNetwork.enable ? var.virtualNetwork.regionName : module.core.resourceLocation.name
  tags = {
    AAA = basename(path.cwd)
  }
}

output privateDNS {
  value = {
    hpc = var.hpcCache.enable ? {
      fqdn    = azurerm_private_dns_a_record.cache_hpc[0].fqdn
      records = azurerm_private_dns_a_record.cache_hpc[0].records
    } : null
    vfxt = var.vfxtCache.enable ? {
      fqdn    = azurerm_private_dns_a_record.cache_vfxt[0].fqdn
      records = azurerm_private_dns_a_record.cache_vfxt[0].records
    } : null
  }
}
