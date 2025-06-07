terraform {
  required_version = ">=1.12.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.32.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>3.4.0"
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
  subscription_id     = data.terraform_remote_state.foundation.outputs.subscriptionId
  storage_use_azuread = true
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

data terraform_remote_state foundation {
  backend = "local"
  config = {
    path = "../../0.Foundation/terraform.tfstate"
  }
}

data azurerm_user_assigned_identity main {
  name                = data.terraform_remote_state.foundation.outputs.managedIdentity.name
  resource_group_name = data.terraform_remote_state.foundation.outputs.resourceGroup.name
}

data azurerm_key_vault main {
  name                = data.terraform_remote_state.foundation.outputs.keyVault.name
  resource_group_name = data.terraform_remote_state.foundation.outputs.resourceGroup.name
}

data azurerm_key_vault_secret admin_username {
  name         = data.terraform_remote_state.foundation.outputs.keyVault.secretName.adminUsername
  key_vault_id = data.azurerm_key_vault.main.id
}

data azurerm_key_vault_secret admin_password {
  name         = data.terraform_remote_state.foundation.outputs.keyVault.secretName.adminPassword
  key_vault_id = data.azurerm_key_vault.main.id
}

data azurerm_key_vault_secret ssh_key_public {
  name         = data.terraform_remote_state.foundation.outputs.keyVault.secretName.sshKeyPublic
  key_vault_id = data.azurerm_key_vault.main.id
}

data azurerm_virtual_network main {
  name                = var.virtualNetwork.name
  resource_group_name = var.virtualNetwork.resourceGroupName
}

data azurerm_subnet cache {
  name                 = var.virtualNetwork.subnetName
  resource_group_name  = data.azurerm_virtual_network.main.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.main.name
}

resource azurerm_resource_group cache {
  name     = var.resourceGroupName
  location = data.azurerm_virtual_network.main.location
  tags = {
    "AAA.Module" = "${basename(dirname(path.cwd))}.${basename(path.cwd)}"
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
