terraform {
  required_version = ">=1.11.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.27.0"
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
  subscription_id     = data.terraform_remote_state.core.outputs.subscriptionId
  storage_use_azuread = true
}

module core {
  source = "../0.Core.Foundation/config"
}

module hammerspace {
  count             = module.core.hammerspace.enable ? 1 : 0
  source            = "../3.File.Storage/Hammerspace"
  resourceGroupName = "${var.resourceGroupName}.Hammerspace"
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

variable managedIdentity {
  type = object({
    name              = string
    resourceGroupName = string
  })
}

variable keyVault {
  type = object({
    enable            = bool
    name              = string
    resourceGroupName = string
    secretName = object({
      adminUsername = string
      adminPassword = string
      sshKeyPublic  = string
    })
  })
}

variable monitorWorkspace {
  type = object({
    name              = string
    resourceGroupName = string
    metricsIngestion = object({
      apiVersion = string
    })
  })
}

variable managedGrafana {
  type = object({
    name              = string
    resourceGroupName = string
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

data azurerm_client_config current {}

data terraform_remote_state core {
  backend = "local"
  config = {
    path = "../0.Core.Foundation/terraform.tfstate"
  }
}

data azurerm_user_assigned_identity studio {
  name                = var.managedIdentity.name
  resource_group_name = var.managedIdentity.resourceGroupName
}

data azurerm_key_vault studio {
  count               = var.keyVault.enable ? 1 : 0
  name                = var.keyVault.name
  resource_group_name = var.keyVault.resourceGroupName
}

data azurerm_key_vault_secret admin_username {
  count        = var.keyVault.enable ? 1 : 0
  name         = var.keyVault.secretName.adminUsername
  key_vault_id = data.azurerm_key_vault.studio[0].id
}

data azurerm_key_vault_secret admin_password {
  count        = var.keyVault.enable ? 1 : 0
  name         = var.keyVault.secretName.adminPassword
  key_vault_id = data.azurerm_key_vault.studio[0].id
}

data azurerm_key_vault_secret ssh_key_public {
  count        = var.keyVault.enable ? 1 : 0
  name         = var.keyVault.secretName.sshKeyPublic
  key_vault_id = data.azurerm_key_vault.studio[0].id
}

data azurerm_monitor_workspace studio {
  name                = var.monitorWorkspace.name
  resource_group_name = var.monitorWorkspace.resourceGroupName
}

data azurerm_monitor_data_collection_endpoint studio {
  name                = basename(data.azurerm_monitor_workspace.studio.default_data_collection_endpoint_id)
  resource_group_name = split("/", data.azurerm_monitor_workspace.studio.default_data_collection_endpoint_id)[4]
}

data azurerm_monitor_data_collection_rule studio {
  name                = basename(data.azurerm_monitor_workspace.studio.default_data_collection_rule_id)
  resource_group_name = split("/", data.azurerm_monitor_workspace.studio.default_data_collection_rule_id)[4]
}

data azurerm_dashboard_grafana studio {
  name                = var.managedGrafana.name
  resource_group_name = var.managedGrafana.resourceGroupName
}

data azurerm_virtual_network studio {
  name                = var.virtualNetwork.name
  resource_group_name = var.virtualNetwork.resourceGroupName
}

data azurerm_subnet cache {
  name                 = var.virtualNetwork.subnetName
  resource_group_name  = data.azurerm_virtual_network.studio.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.studio.name
}

resource azurerm_resource_group cache {
  name     = var.resourceGroupName
  location = data.azurerm_virtual_network.studio.location
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
