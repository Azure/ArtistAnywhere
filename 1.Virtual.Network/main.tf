terraform {
  required_version = ">= 1.7.2"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.90.0"
    }
  }
  backend azurerm {
    key = "1.Virtual.Network"
  }
}

provider azurerm {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

module global {
  source = "../0.Global.Foundation/module"
}

variable resourceGroupName {
  type = string
}

data azurerm_client_config studio {}

data azurerm_key_vault studio {
  name                = module.global.keyVault.name
  resource_group_name = module.global.resourceGroupName
}

data azurerm_key_vault_secret gateway_connection {
  name         = module.global.keyVault.secretName.gatewayConnection
  key_vault_id = data.azurerm_key_vault.studio.id
}

data azurerm_key_vault batch {
  name                = "${module.global.keyVault.name}-batch"
  resource_group_name = module.global.resourceGroupName
}

data azurerm_storage_account studio {
  name                = module.global.rootStorage.accountName
  resource_group_name = module.global.resourceGroupName
}

resource azurerm_resource_group network {
  name     = var.resourceGroupName
  location = local.virtualNetwork.regionName
  tags = {
    nameSuffix = local.virtualNetwork.nameSuffix
  }
}

resource azurerm_resource_group network_regions {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.name => virtualNetwork
  }
  name     = each.value.resourceGroupName
  location = each.value.regionName
  tags = {
    nameSuffix = each.value.nameSuffix
  }
}
