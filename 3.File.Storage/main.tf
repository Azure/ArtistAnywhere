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
    http = {
      source  = "hashicorp/http"
      version = "~>3.4.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~>0.13.0"
    }
    azapi = {
      source = "azure/azapi"
      version = "~>2.3.0"
    }
  }
  backend azurerm {
    key              = "3.File.Storage"
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
  })
}

variable existingNetwork {
  type = object({
    enable             = bool
    name               = string
    subnetNameIdentity = string
    subnetNameStorage  = string
    resourceGroupName  = string
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
      ip   = string
      name = string
      adminLogin = object({
        userName     = string
        userPassword = string
      })
    })
  })
}

data http client_address {
  url = "https://api.ipify.org?format=json"
}

data azurerm_subscription current {}

data azurerm_client_config current {}

data azurerm_location studio {
  location = local.location
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

data azurerm_resource_group dns {
  name = var.existingNetwork.enable ? var.existingNetwork.privateDNS.resourceGroupName : data.terraform_remote_state.network.outputs.dns.privateZone.resourceGroup.name
}

data azurerm_virtual_network studio {
  name                = var.existingNetwork.enable ? var.existingNetwork.name : data.terraform_remote_state.network.outputs.virtualNetwork.core.name
  resource_group_name = var.existingNetwork.enable ? var.existingNetwork.resourceGroupName : var.regionName != "" ? "${data.azurerm_resource_group.dns.name}.${var.regionName}" : data.terraform_remote_state.network.outputs.virtualNetwork.core.resourceGroup.name
}

data azurerm_private_dns_zone studio {
  name                = var.existingNetwork.enable ? var.existingNetwork.privateDNS.zoneName : data.terraform_remote_state.network.outputs.dns.privateZone.name
  resource_group_name = var.existingNetwork.enable ? var.existingNetwork.privateDNS.zone.resourceGroup.name : data.terraform_remote_state.network.outputs.dns.privateZone.resourceGroup.name
}

data azurerm_subnet storage {
  name                 = var.existingNetwork.enable ? var.existingNetwork.subnetNameStorage : "Storage"
  resource_group_name  = data.azurerm_virtual_network.studio.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.studio.name
}

locals {
  location = var.regionName != "" ? var.regionName : module.core.resourceLocation.name
}

resource azurerm_resource_group storage {
  count    = length(local.storageAccounts) > 0 ? 1 : 0
  name     = var.resourceGroupName
  location = local.location
  tags = {
    AAA = basename(path.cwd)
  }
}

resource azurerm_resource_group hammerspace {
  count    = var.hammerspace.enable ? 1 : 0
  name     = "${var.resourceGroupName}.Hammerspace"
  location = local.location
  tags = {
    AAA = basename(path.cwd)
  }
}

output hammerspace {
  value = var.hammerspace.enable ? {
    metadata = module.hammerspace[0].dnsMetadata
    data     = module.hammerspace[0].dnsData
  } : null
}
