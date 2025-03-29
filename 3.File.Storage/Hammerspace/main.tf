module core {
  source = "../../0.Core.Foundation/config"
}

variable resourceGroupName {
  type = string
}

variable regionName {
  type = string
}

variable hammerspace {
  type = object({
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

variable dnsRecord {
  type = object({
    name       = string
    ttlSeconds = number
    metadataTier = object({
      enable = bool
    })
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

data azurerm_resource_group dns {
  name = var.virtualNetwork.enable ? var.virtualNetwork.privateDNS.resourceGroupName : data.terraform_remote_state.network.outputs.privateDNS.zone.resourceGroup.name
}

data azurerm_virtual_network studio {
  name                = var.virtualNetwork.enable ? var.virtualNetwork.name : data.terraform_remote_state.network.outputs.virtualNetwork.default.name
  resource_group_name = var.virtualNetwork.enable ? var.virtualNetwork.resourceGroupName : var.regionName != "" ? "${data.azurerm_resource_group.dns.name}.${var.regionName}" : data.terraform_remote_state.network.outputs.virtualNetwork.default.resourceGroup.name
}

data azurerm_subnet storage {
  name                 = var.virtualNetwork.enable ? var.virtualNetwork.subnetName : "Storage"
  resource_group_name  = data.azurerm_virtual_network.studio.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.studio.name
}

data azurerm_private_dns_zone studio {
  name                = var.virtualNetwork.enable ? var.virtualNetwork.privateDNS.zoneName : data.terraform_remote_state.network.outputs.privateDNS.zone.name
  resource_group_name = var.virtualNetwork.enable ? var.virtualNetwork.privateDNS.zone.resourceGroup.name : data.terraform_remote_state.network.outputs.privateDNS.zone.resourceGroup.name
}

locals {
  hsImage = {
    publisher = "Hammerspace"
    product   = "Hammerspace_BYOL_5_0"
    name      = "Hammerspace_5_0"
    version   = var.hammerspace.version
  }
  hsSubnetSize = "/${reverse(split("/", data.azurerm_subnet.storage.address_prefixes[0]))[0]}"
  location = var.regionName != "" ? var.regionName : module.core.resourceLocation.name
}

resource azurerm_resource_group hammerspace {
  name     = var.resourceGroupName
  location = local.location
  tags = {
    AAA = basename(path.cwd)
  }
}
