terraform {
  required_version = ">=1.10.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.14.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>3.0.0"
    }
    avere = {
      source  = "hashicorp/avere"
      version = "~>1.3.0"
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
  privateDns = {
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
    domainName   = var.activeDirectory.domainName
    servers      = var.activeDirectory.servers
    userName     = var.activeDirectory.userName != "" ? var.activeDirectory.userName : data.azurerm_key_vault_secret.admin_username.value
    userPassword = var.activeDirectory.userPassword != "" ? var.activeDirectory.userPassword : data.azurerm_key_vault_secret.admin_password.value
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
          cachingType = string
          sizeGB      = number
        })
        dataDisk = object({
          storageType = string
          cachingType = string
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
          cachingType = string
          sizeGB      = number
        })
        dataDisk = object({
          storageType = string
          cachingType = string
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

variable activeDirectory {
  type = object({
    enable       = bool
    domainName   = string
    servers      = string
    userName     = string
    userPassword = string
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

data azurerm_key_vault_key data_encryption {
  name         = module.global.keyVault.keyName.dataEncryption
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

data terraform_remote_state storage {
  backend = "azurerm"
  config = {
    resource_group_name  = module.global.resourceGroupName
    storage_account_name = module.global.storage.accountName
    container_name       = module.global.storage.containerName.terraformState
    key                  = "3.File.Storage"
    use_azuread_auth     = true
  }
}

data azurerm_virtual_network studio {
  name                = var.existingNetwork.enable ? var.existingNetwork.name : data.terraform_remote_state.network.outputs.virtualNetworks[0].name
  resource_group_name = var.existingNetwork.enable ? var.existingNetwork.resourceGroupName : data.terraform_remote_state.network.outputs.virtualNetworks[0].resourceGroupName
}

data azurerm_subnet cache {
  name                 = var.existingNetwork.enable ? var.existingNetwork.subnetName : "Cache"
  resource_group_name  = data.azurerm_virtual_network.studio.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.studio.name
}

data azurerm_private_dns_zone studio {
  name                = var.existingNetwork.enable ? var.existingNetwork.privateDns.zoneName : data.terraform_remote_state.network.outputs.privateDns.zoneName
  resource_group_name = var.existingNetwork.enable ? var.existingNetwork.privateDns.resourceGroupName : data.terraform_remote_state.network.outputs.privateDns.resourceGroupName
}

resource azurerm_resource_group cache {
  name     = var.resourceGroupName
  location = var.existingNetwork.enable ? var.existingNetwork.regionName : module.global.resourceLocation.regionName
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
  } : var.knfsdCache.enable ? {
    fqdn    = azurerm_private_dns_a_record.cache_knfsd[0].fqdn
    records = azurerm_private_dns_a_record.cache_knfsd[0].records
  } : null
}
