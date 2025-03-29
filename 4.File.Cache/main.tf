terraform {
  required_version = ">=1.11.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.25.0"
    }
  }
  backend azurerm {
    key              = "4.File.Cache"
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

module hammerspace {
  count             = module.core.hammerspace.enable ? 1 : 0
  source            = "../3.File.Storage/Hammerspace"
  resourceGroupName = "${var.resourceGroupName}.Hammerspace"
  regionName        = module.core.resourceLocation.name
  dnsRecord         = merge(var.dnsRecord, {metadataTier={enable=false}})
  virtualNetwork    = var.virtualNetwork
  activeDirectory   = var.activeDirectory
  hammerspace = merge(module.core.hammerspace, {
    shares = [
      {
        enable = false
        name   = "cache"
        path   = "/cache"
        size   = 0
        export = "*,ro,root-squash,insecure"
      }
    ]
    volumes = [
      {
        enable = false
        name   = "data-cpu"
        type   = "READ_ONLY"
        path   = "/data/cpu"
        node = {
          name    = "node1"
          type    = "OTHER"
          address = "10.1.194.4"
        }
        assimilation = {
          enable = true
          share = {
            name = "cache"
            path = {
              source      = "/"
              destination = "/moana"
            }
          }
        }
      },
      {
        enable = false
        name   = "data-gpu"
        type   = "READ_ONLY"
        path   = "/data/gpu"
        node = {
          name    = "node2"
          type    = "OTHER"
          address = "10.1.194.4"
        }
        assimilation = {
          enable = true
          share = {
            name = "cache"
            path = {
              source      = "/"
              destination = "/blender"
            }
          }
        }
      }
    ]
    volumeGroups = [
      {
        enable = false
        name   = "cache"
        volumeNames = [
          "data-cpu",
          "data-gpu"
        ]
      }
    ]
  })
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
    nfs = var.nfsCache.enable ? {
      fqdn    = azurerm_private_dns_a_record.cache_nfs[0].fqdn
      records = azurerm_private_dns_a_record.cache_nfs[0].records
    } : null
    hs = module.core.hammerspace.enable ? {
      fqdn    = module.hammerspace[0].privateDNS.fqdn
      records = module.hammerspace[0].privateDNS.records
    } : null
  }
}
