terraform {
  required_version = ">=1.12.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.29.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>3.4.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~>3.5.0"
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
  subscription_id     = data.terraform_remote_state.foundation.outputs.subscriptionId
  storage_use_azuread = true
}

module config {
  source = "../0.Foundation/config"
}

module hammerspace {
  count             = module.config.hammerspace.enable ? 1 : 0
  source            = "../3.File.Storage/Hammerspace"
  resourceGroupName = "${var.resourceGroupName}.Hammerspace"
  dnsRecord         = merge(var.dnsRecord, {metadataTier={enable=false}})
  virtualNetwork    = var.virtualNetwork
  activeDirectory   = var.activeDirectory
  hammerspace       = module.config.hammerspace
}

variable resourceGroupName {
  type = string
}

variable extendedZone {
  type = object({
    enable   = bool
    name     = string
    location = string
  })
}

variable dnsRecord {
  type = object({
    name       = string
    ttlSeconds = number
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

data http client_address {
  url = "https://api.ipify.org?format=json"
}

data azurerm_subscription current {}

data azurerm_client_config current {}

data azurerm_location main {
  location = data.azurerm_virtual_network.main.location
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

data azurerm_key_vault_key data_encryption {
  name         = data.terraform_remote_state.foundation.outputs.keyVault.keyName.dataEncryption
  key_vault_id = data.azurerm_key_vault.main.id
}

data azurerm_resource_group dns {
  name = var.virtualNetwork.privateDNS.resourceGroupName
}

data azurerm_virtual_network main {
  name                = var.virtualNetwork.name
  resource_group_name = var.virtualNetwork.resourceGroupName
}

data azurerm_subnet storage {
  name                 = var.virtualNetwork.subnetName
  resource_group_name  = data.azurerm_virtual_network.main.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.main.name
}

resource azurerm_resource_group storage {
  count    = length(local.storageAccounts) > 0 ? 1 : 0
  name     = var.resourceGroupName
  location = data.azurerm_virtual_network.main.location
  tags = {
    "AAA.Module" = basename(path.cwd)
  }
}

############################################################################
# Private DNS (https://learn.microsoft.com/azure/dns/private-dns-overview) #
############################################################################

resource azurerm_private_dns_a_record netapp {
  count               = var.netAppFiles.enable && length(azurerm_netapp_volume.main) > 0 ? 1 : 0
  name                = "${lower(var.dnsRecord.name)}-netapp"
  resource_group_name = var.virtualNetwork.privateDNS.resourceGroupName
  zone_name           = var.virtualNetwork.privateDNS.zoneName
  ttl                 = var.dnsRecord.ttlSeconds
  records = distinct([
    for volume in azurerm_netapp_volume.main : volume.mount_ip_addresses[0]
  ])
}

resource azurerm_private_dns_a_record lustre {
  count               = var.managedLustre.enable ? 1 : 0
  name                = "${lower(var.dnsRecord.name)}-lustre"
  resource_group_name = var.virtualNetwork.privateDNS.resourceGroupName
  zone_name           = var.virtualNetwork.privateDNS.zoneName
  ttl                 = var.dnsRecord.ttlSeconds
  records = [
    azurerm_managed_lustre_file_system.main[0].mgs_address
  ]
}

output privateDNS {
  value = {
    netAppFiles = var.netAppFiles.enable && length(azurerm_netapp_volume.main) > 0 ? {
      fqdn    = azurerm_private_dns_a_record.netapp[0].fqdn
      records = azurerm_private_dns_a_record.netapp[0].records
    } : null
    managedLustre = var.managedLustre.enable ? {
      fqdn    = azurerm_private_dns_a_record.lustre[0].fqdn
      records = azurerm_private_dns_a_record.lustre[0].records
    } : null
    hammerspace = module.config.hammerspace.enable ? {
      fqdn    = module.hammerspace[0].privateDNS.fqdn
      records = module.hammerspace[0].privateDNS.records
    } : null
  }
}
