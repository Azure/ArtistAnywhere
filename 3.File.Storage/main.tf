terraform {
  required_version = ">=1.11.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.25.0"
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
  count             = module.core.hammerspace.enable ? 1 : 0
  source            = "../3.File.Storage/Hammerspace"
  resourceGroupName = "${var.resourceGroupName}.Hammerspace"
  regionName        = local.location
  dnsRecord         = merge(var.dnsRecord, {metadataTier={enable=false}})
  virtualNetwork    = var.virtualNetwork
  activeDirectory   = var.activeDirectory
  hammerspace       = module.core.hammerspace
}

variable resourceGroupName {
  type = string
}

variable regionName {
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

############################################################################
# Private DNS (https://learn.microsoft.com/azure/dns/private-dns-overview) #
############################################################################

resource azurerm_private_dns_a_record netapp {
  count               = var.netAppFiles.enable && length(azurerm_netapp_volume.studio) > 0 ? 1 : 0
  name                = "${lower(var.dnsRecord.name)}-netapp"
  resource_group_name = data.azurerm_private_dns_zone.studio.resource_group_name
  zone_name           = data.azurerm_private_dns_zone.studio.name
  ttl                 = var.dnsRecord.ttlSeconds
  records = distinct([
    for volume in azurerm_netapp_volume.studio : volume.mount_ip_addresses[0]
  ])
}

resource azurerm_private_dns_a_record lustre {
  count               = var.managedLustre.enable ? 1 : 0
  name                = "${lower(var.dnsRecord.name)}-lustre"
  resource_group_name = data.azurerm_private_dns_zone.studio.resource_group_name
  zone_name           = data.azurerm_private_dns_zone.studio.name
  ttl                 = var.dnsRecord.ttlSeconds
  records = [
    azurerm_managed_lustre_file_system.studio[0].mgs_address
  ]
}

output privateDNS {
  value = {
    netAppFiles = var.netAppFiles.enable && length(azurerm_netapp_volume.studio) > 0 ? {
      fqdn    = azurerm_private_dns_a_record.netapp[0].fqdn
      records = azurerm_private_dns_a_record.netapp[0].records
    } : null
    managedLustre = var.managedLustre.enable ? {
      fqdn    = azurerm_private_dns_a_record.lustre[0].fqdn
      records = azurerm_private_dns_a_record.lustre[0].records
    } : null
    hammerspace = module.core.hammerspace.enable ? {
      fqdn    = module.hammerspace[0].privateDNS.fqdn
      records = module.hammerspace[0].privateDNS.records
    } : null
  }
}
