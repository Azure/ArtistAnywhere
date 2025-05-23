terraform {
  required_version = ">=1.12.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.29.0"
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
  subscription_id     = data.terraform_remote_state.foundation.outputs.subscriptionId
  storage_use_azuread = true
}

module config {
  source = "../0.Foundation/Config"
}

module hammerspace {
  count             = module.config.hammerspace.enable ? 1 : 0
  source            = "../3.File.Storage/Hammerspace"
  resourceGroupName = "${var.resourceGroupName}.Hammerspace"
  dnsRecord         = merge(var.dnsRecord, {metadataTier={enable=false}})
  virtualNetwork    = var.virtualNetwork
  activeDirectory   = var.activeDirectory
  hammerspace = merge(module.config.hammerspace, {
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

data terraform_remote_state foundation {
  backend = "local"
  config = {
    path = "../0.Foundation/terraform.tfstate"
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

data azurerm_app_configuration_keys main {
  configuration_store_id = data.terraform_remote_state.foundation.outputs.appConfig.id
}

data azurerm_monitor_workspace main {
  name                = var.monitorWorkspace.name
  resource_group_name = var.monitorWorkspace.resourceGroupName
}

data azurerm_monitor_data_collection_endpoint main {
  name                = basename(data.azurerm_monitor_workspace.main.default_data_collection_endpoint_id)
  resource_group_name = split("/", data.azurerm_monitor_workspace.main.default_data_collection_endpoint_id)[4]
}

data azurerm_monitor_data_collection_rule main {
  name                = basename(data.azurerm_monitor_workspace.main.default_data_collection_rule_id)
  resource_group_name = split("/", data.azurerm_monitor_workspace.main.default_data_collection_rule_id)[4]
}

data azurerm_dashboard_grafana main {
  name                = var.managedGrafana.name
  resource_group_name = var.managedGrafana.resourceGroupName
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
    "AAA.Module" = basename(path.cwd)
  }
}

output privateDNS {
  value = {
    nfs = var.nfsCache.enable ? {
      fqdn    = azurerm_private_dns_a_record.cache_nfs[0].fqdn
      records = azurerm_private_dns_a_record.cache_nfs[0].records
    } : null
    hs = module.config.hammerspace.enable ? {
      fqdn    = module.hammerspace[0].privateDNS.fqdn
      records = module.hammerspace[0].privateDNS.records
    } : null
  }
}
