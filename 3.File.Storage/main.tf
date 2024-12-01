terraform {
  required_version = ">=1.10.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.12.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>3.0.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~>3.4.0"
    }
    azapi = {
      source = "azure/azapi"
      version = "~>2.0.0"
    }
  }
  backend azurerm {
    key              = "3.File.Storage"
    use_azuread_auth = true
  }
}

provider azurerm {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    managed_disk {
      expand_without_downtime = true
    }
    virtual_machine {
      delete_os_disk_on_deletion            = true
      detach_implicit_data_disk_on_deletion = false
      skip_shutdown_and_force_delete        = false
      graceful_shutdown                     = false
    }
    virtual_machine_scale_set {
      reimage_on_manual_upgrade     = true
      roll_instances_when_required  = true
      scale_to_zero_before_deletion = true
      force_delete                  = false
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
  source      = "./Hammerspace"
  hammerspace = var.hammerspace
  resourceGroup = {
    name     = azurerm_resource_group.hammerspace[0].name
    location = azurerm_resource_group.hammerspace[0].location
  }
  virtualNetwork = {
    name              = data.azurerm_subnet.storage.virtual_network_name
    subnetName        = data.azurerm_subnet.storage.name
    resourceGroupName = data.azurerm_subnet.storage.resource_group_name
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
  depends_on = [
    azurerm_resource_group.hammerspace
  ]
}

variable resourceGroupName {
  type = string
}

variable regionName {
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

data http client_address {
  url = "https://api.ipify.org?format=json"
}

data azurerm_client_config studio {}

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

data azurerm_key_vault_secret ssh_key_private {
  name         = module.global.keyVault.secretName.sshKeyPrivate
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

data terraform_remote_state image {
  backend = "azurerm"
  config = {
    resource_group_name  = module.global.resourceGroupName
    storage_account_name = module.global.storage.accountName
    container_name       = module.global.storage.containerName.terraformState
    key                  = "2.Image.Builder"
    use_azuread_auth     = true
  }
}

data azurerm_resource_group dns {
  name = var.existingNetwork.enable ? var.existingNetwork.privateDns.resourceGroupName : data.terraform_remote_state.network.outputs.privateDns.resourceGroupName
}

data azurerm_virtual_network studio {
  name                = var.existingNetwork.enable ? var.existingNetwork.name : data.terraform_remote_state.network.outputs.virtualNetworks[0].name
  resource_group_name = var.existingNetwork.enable ? var.existingNetwork.resourceGroupName : var.regionName != "" ? "${data.azurerm_resource_group.dns.name}.${var.regionName}" : data.terraform_remote_state.network.outputs.virtualNetworks[0].resourceGroupName
}

data azurerm_private_dns_zone studio {
  name                = var.existingNetwork.enable ? var.existingNetwork.privateDns.zoneName : data.terraform_remote_state.network.outputs.privateDns.zoneName
  resource_group_name = var.existingNetwork.enable ? var.existingNetwork.privateDns.resourceGroupName : data.terraform_remote_state.network.outputs.privateDns.resourceGroupName
}

data azurerm_subnet storage {
  name                 = var.existingNetwork.enable ? var.existingNetwork.subnetName : "Storage"
  resource_group_name  = data.azurerm_virtual_network.studio.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.studio.name
}

locals {
  regionName = var.regionName != "" ? var.regionName : module.global.resourceLocation.regionName
}

resource azurerm_resource_group storage {
  count    = length(local.storageAccounts) > 0 ? 1 : 0
  name     = var.resourceGroupName
  location = local.regionName
  tags = {
    AAA = basename(path.cwd)
  }
}

resource azurerm_resource_group hammerspace {
  count    = var.hammerspace.enable ? 1 : 0
  name     = "${var.resourceGroupName}.Hammerspace"
  location = local.regionName
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
