terraform {
  required_version = ">=1.11.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.24.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>3.2.0"
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
    key              = "4.File.Cache"
    use_azuread_auth = true
  }
}

provider azurerm {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id     = data.terraform_remote_state.core.outputs.subscription.id
  storage_use_azuread = true
}

module core {
  source = "../0.Core.Foundation/config"
}

module hammerspace {
  count       = var.hammerspace.enable ? 1 : 0
  source      = "../3.File.Storage/Hammerspace"
  hammerspace = var.hammerspace
  resourceGroup = {
    name     = azurerm_resource_group.cache.name
    location = azurerm_resource_group.cache.location
  }
  virtualNetwork = {
    name              = data.azurerm_subnet.cache.virtual_network_name
    subnetName        = data.azurerm_subnet.cache.name
    resourceGroupName = data.azurerm_subnet.cache.resource_group_name
  }
  privateDNS = {
    zoneName          = data.azurerm_private_dns_zone.studio.name
    resourceGroupName = data.azurerm_private_dns_zone.studio.resource_group_name
    aRecord = {
      name       = var.dnsRecord.name
      ttlSeconds = var.dnsRecord.ttlSeconds
    }
  }
  adminLogin = {
    userName     = data.azurerm_key_vault_secret.admin_username.value
    userPassword = data.azurerm_key_vault_secret.admin_password.value
    sshKeyPublic = data.azurerm_key_vault_secret.ssh_key_public.value
  }
  activeDirectory = {
    enable       = var.activeDirectory.enable
    domainName   = var.activeDirectory.domain.name
    servers      = var.activeDirectory.machine.name
    userName     = var.activeDirectory.machine.adminLogin.userName != "" ? var.activeDirectory.machine.adminLogin.userName : data.azurerm_key_vault_secret.admin_username.value
    userPassword = var.activeDirectory.machine.adminLogin.userPassword != "" ? var.activeDirectory.machine.adminLogin.userPassword : data.azurerm_key_vault_secret.admin_password.value
  }
  depends_on = [
    azurerm_resource_group.cache
  ]
}

variable resourceGroupName {
  type = string
}

variable hammerspace {
  type = object({
    enable     = bool
    version    = string
    namePrefix = string
    domainName = string
    metadata = object({
      machine = object({
        namePrefix = string
        size       = string
        count      = number
        osDisk = object({
          storageType = string
          cachingMode = string
          sizeGB      = number
        })
        dataDisk = object({
          storageType = string
          cachingMode = string
          sizeGB      = number
        })
        adminLogin = object({
          userName     = string
          userPassword = string
          sshKeyPublic = string
          passwordAuth = object({
            disable = bool
          })
        })
      })
      network = object({
        acceleration = object({
          enable = bool
        })
      })
    })
    data = object({
      machine = object({
        namePrefix = string
        size       = string
        count      = number
        osDisk = object({
          storageType = string
          cachingMode = string
          sizeGB      = number
        })
        dataDisk = object({
          storageType = string
          cachingMode = string
          sizeGB      = number
          count       = number
          raid0 = object({
            enable = bool
          })
        })
        adminLogin = object({
          userName     = string
          userPassword = string
          sshKeyPublic = string
          passwordAuth = object({
            disable = bool
          })
        })
      })
      network = object({
        acceleration = object({
          enable = bool
        })
      })
    })
    proximityPlacementGroup = object({
      enable = bool
    })
    storageAccounts = list(object({
      enable    = bool
      name      = string
      accessKey = string
    }))
    shares = list(object({
      enable = bool
      name   = string
      path   = string
      size   = number
      export = string
    }))
    volumes = list(object({
      enable = bool
      name   = string
      type   = string
      path   = string
      node = object({
        name    = string
        type    = string
        address = string
      })
      assimilation = object({
        enable = bool
        share = object({
          name = string
          path = object({
            source      = string
            destination = string
          })
        })
      })
    }))
    volumeGroups = list(object({
      enable      = bool
      name        = string
      volumeNames = list(string)
    }))
  })
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

variable existingNetwork {
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

data azurerm_key_vault_key data_encryption {
  name         = module.core.keyVault.keyName.dataEncryption
  key_vault_id = data.azurerm_key_vault.studio.id
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

data terraform_remote_state storage {
  backend = "azurerm"
  config = {
    subscription_id      = data.terraform_remote_state.core.outputs.subscription.id
    resource_group_name  = data.terraform_remote_state.core.outputs.resourceGroup.name
    storage_account_name = data.terraform_remote_state.core.outputs.storage.account.name
    container_name       = data.terraform_remote_state.core.outputs.storage.containerName.terraformState
    key                  = "3.File.Storage"
    use_azuread_auth     = true
  }
}

data azurerm_virtual_network studio {
  name                = var.existingNetwork.enable ? var.existingNetwork.name : data.terraform_remote_state.network.outputs.virtualNetwork.core.name
  resource_group_name = var.existingNetwork.enable ? var.existingNetwork.resourceGroupName : data.terraform_remote_state.network.outputs.virtualNetwork.core.resourceGroup.name
}

data azurerm_subnet cache {
  name                 = var.existingNetwork.enable ? var.existingNetwork.subnetName : "Cache"
  resource_group_name  = data.azurerm_virtual_network.studio.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.studio.name
}

data azurerm_private_dns_zone studio {
  name                = var.existingNetwork.enable ? var.existingNetwork.privateDNS.zoneName : data.terraform_remote_state.network.outputs.dns.privateZone.name
  resource_group_name = var.existingNetwork.enable ? var.existingNetwork.privateDNS.resourceGroupName : data.terraform_remote_state.network.outputs.dns.privateZone.resourceGroup.name
}

resource azurerm_resource_group cache {
  name     = var.resourceGroupName
  location = var.existingNetwork.enable ? var.existingNetwork.regionName : module.core.resourceLocation.name
  tags = {
    AAA = basename(path.cwd)
  }
}

output hammerspaceDNSMetadata {
  value = var.hammerspace.enable ? module.hammerspace[0].dnsMetadata : null
}

output hammerspaceDNSData {
  value = var.hammerspace.enable ? module.hammerspace[0].dnsData : null
}

output cacheDNS {
  value = var.hpcCache.enable ? {
    fqdn    = azurerm_private_dns_a_record.cache_hpc[0].fqdn
    records = azurerm_private_dns_a_record.cache_hpc[0].records
  } : var.vfxtCache.enable ? {
    fqdn    = azurerm_private_dns_a_record.cache_vfxt[0].fqdn
    records = azurerm_private_dns_a_record.cache_vfxt[0].records
  } : var.nfsCache.enable ? {
    fqdn    = azurerm_private_dns_a_record.cache_nfs[0].fqdn
    records = azurerm_private_dns_a_record.cache_nfs[0].records
  } : null
}
