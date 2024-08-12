terraform {
  required_version = ">= 1.9.4"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.115.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>2.53.1"
    }
    external = {
      source  = "hashicorp/external"
      version = "~>2.3.3"
    }
    http = {
      source  = "hashicorp/http"
      version = "~>3.4.4"
    }
    azapi = {
      source = "azure/azapi"
      version = "~>1.14.0"
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
      delete_os_disk_on_deletion     = true
      skip_shutdown_and_force_delete = false
      graceful_shutdown              = false
    }
    virtual_machine_scale_set {
      force_delete                  = false
      reimage_on_manual_upgrade     = true
      roll_instances_when_required  = true
      scale_to_zero_before_deletion = true
    }
  }
  storage_use_azuread = true
}

module global {
  source = "../0.Global.Foundation/config"
}

variable resourceGroupName {
  type = string
}

variable fileLoadSource {
  type = object({
    enable        = bool
    accountName   = string
    accountKey    = string
    containerName = string
    blobName      = string
  })
}

variable subscriptionId {
  type = object({
    terraformState = string
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

data azurerm_key_vault_key data_encryption {
  name         = module.global.keyVault.keyName.dataEncryption
  key_vault_id = data.azurerm_key_vault.studio.id
}

data terraform_remote_state network {
  backend = "azurerm"
  config = {
    subscription_id      = local.subscriptionId.terraformState
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
    subscription_id      = local.subscriptionId.terraformState
    resource_group_name  = module.global.resourceGroupName
    storage_account_name = module.global.storage.accountName
    container_name       = module.global.storage.containerName.terraformState
    key                  = "2.Image.Builder"
    use_azuread_auth     = true
  }
}

data azurerm_resource_group dns {
  name = data.terraform_remote_state.network.outputs.privateDns.resourceGroupName
}

data azurerm_virtual_network studio_region {
  name                = data.terraform_remote_state.network.outputs.virtualNetworks[0].name
  resource_group_name = data.terraform_remote_state.network.outputs.virtualNetworks[0].resourceGroupName
}

data azurerm_virtual_network studio_edge {
  name                = reverse(data.terraform_remote_state.network.outputs.virtualNetworks)[0].name
  resource_group_name = reverse(data.terraform_remote_state.network.outputs.virtualNetworks)[0].resourceGroupName
}

data azurerm_subnet storage_region {
  name                 = "Storage"
  resource_group_name  = data.azurerm_virtual_network.studio_region.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.studio_region.name
}

# data azurerm_subnet storage_edge {
#   name                 = "Storage"
#   resource_group_name  = data.azurerm_virtual_network.studio_edge.resource_group_name
#   virtual_network_name = data.azurerm_virtual_network.studio_edge.name
# }

data azurerm_private_dns_zone studio {
  name                = data.terraform_remote_state.network.outputs.privateDns.zoneName
  resource_group_name = data.terraform_remote_state.network.outputs.privateDns.resourceGroupName
}

locals {
  subscriptionId = {
    terraformState = var.subscriptionId.terraformState != "" ? var.subscriptionId.terraformState : data.azurerm_client_config.studio.subscription_id
  }
}

resource azurerm_resource_group storage {
  name     = var.resourceGroupName
  location = module.global.resourceLocation.regionName
}
