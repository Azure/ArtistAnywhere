terraform {
  required_version = ">= 1.8.2"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.101.0"
    }
  }
  backend azurerm {
    key = "1.Virtual.Network.AI"
  }
}

provider azurerm {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    cognitive_account {
      purge_soft_delete_on_destroy = true
    }
  }
}

module global {
  source = "../../0.Global.Foundation/config"
}

variable ai {
  type = object({
    enable     = bool
    name       = string
    tier       = string
    domainName = string
    open = object({
      enable     = bool
      name       = string
      tier       = string
      domainName = string
    })
    speech = object({
      enable     = bool
      name       = string
      tier       = string
      domainName = string
    })
    language = object({
      conversational = object({
        enable     = bool
        name       = string
        tier       = string
        domainName = string
      })
      textAnalytics = object({
        enable     = bool
        name       = string
        tier       = string
        domainName = string
      })
      textTranslation = object({
        enable     = bool
        name       = string
        tier       = string
        domainName = string
      })
    })
    vision = object({
      enable     = bool
      name       = string
      tier       = string
      domainName = string
      training = object({
        enable     = bool
        name       = string
        tier       = string
        regionName = string
        domainName = string
      })
      prediction = object({
        enable     = bool
        name       = string
        tier       = string
        regionName = string
        domainName = string
      })
    })
    face = object({
      enable     = bool
      name       = string
      tier       = string
      domainName = string
    })
    document = object({
      enable     = bool
      name       = string
      tier       = string
      domainName = string
    })
    encryption = object({
      enable = bool
    })
  })
}

data http client_address {
  url = "https://api.ipify.org?format=json"
}

data azurerm_user_assigned_identity studio {
  name                = module.global.managedIdentity.name
  resource_group_name = module.global.resourceGroupName
}

data azurerm_storage_account studio {
  name                = module.global.storage.accountName
  resource_group_name = module.global.resourceGroupName
}

data azurerm_search_service studio {
  count               = module.global.search.enable ? 1 : 0
  name                = module.global.search.name
  resource_group_name = module.global.resourceGroupName
}

data azurerm_key_vault studio {
  count               = module.global.keyVault.enable ? 1 : 0
  name                = module.global.keyVault.name
  resource_group_name = module.global.resourceGroupName
}

data azurerm_key_vault_key data_encryption {
  count        = module.global.keyVault.enable ? 1 : 0
  name         = module.global.keyVault.keyName.dataEncryption
  key_vault_id = data.azurerm_key_vault.studio[0].id
}

data terraform_remote_state network {
  backend = "azurerm"
  config = {
    resource_group_name  = module.global.resourceGroupName
    storage_account_name = module.global.storage.accountName
    container_name       = module.global.storage.containerName.terraformState
    key                  = "1.Virtual.Network"
  }
}

data azurerm_virtual_network studio_region {
  name                = data.terraform_remote_state.network.outputs.virtualNetworks[0].name
  resource_group_name = data.terraform_remote_state.network.outputs.virtualNetworks[0].resourceGroupName
}

data azurerm_subnet ai {
  name                 = "AI"
  resource_group_name  = data.azurerm_virtual_network.studio_region.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.studio_region.name
}

locals {
  virtualNetworks              = data.terraform_remote_state.network.outputs.virtualNetworks
  virtualNetworksSubnetCompute = data.terraform_remote_state.network.outputs.virtualNetworksSubnetCompute
}

resource azurerm_resource_group ai {
  name     = "${module.global.resourceGroupName}.AI"
  location = module.global.resourceLocation.regionName
}

resource azurerm_cognitive_account ai {
  count                 = var.ai.enable ? 1 : 0
  name                  = var.ai.name
  resource_group_name   = azurerm_resource_group.ai.name
  location              = azurerm_resource_group.ai.location
  sku_name              = var.ai.tier
  custom_subdomain_name = var.ai.domainName != "" ? var.ai.domainName : var.ai.name
  kind                  = "CognitiveServices"
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  network_acls {
    default_action = "Deny"
    virtual_network_rules {
      subnet_id = data.azurerm_subnet.ai.id
    }
    ip_rules = [
      jsondecode(data.http.client_address.response_body).ip
    ]
  }
  dynamic customer_managed_key {
    for_each = module.global.keyVault.enable && var.ai.encryption.enable ? [1] : []
    content {
      key_vault_key_id = data.azurerm_key_vault_key.data_encryption[0].id
    }
  }
}

resource azurerm_private_dns_zone ai {
  count               = var.ai.enable ? 1 : 0
  name                = "privatelink.cognitiveservices.azure.com"
  resource_group_name = azurerm_resource_group.ai.name
}

resource azurerm_private_dns_zone_virtual_network_link ai {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.key => virtualNetwork if var.ai.enable
  }
  name                  = "${lower(each.value.key)}-ai"
  resource_group_name   = azurerm_private_dns_zone.ai[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.ai[0].name
  virtual_network_id    = each.value.id
}

resource azurerm_private_endpoint ai {
  for_each = {
    for subnet in local.virtualNetworksSubnetCompute : subnet.key => subnet if var.ai.enable && subnet.virtualNetworkEdgeZone == ""
  }
  name                = "${lower(each.value.virtualNetworkName)}-ai"
  resource_group_name = each.value.resourceGroupName
  location            = each.value.regionName
  subnet_id           = "${each.value.virtualNetworkId}/subnets/${each.value.name}"
  private_service_connection {
    name                           = azurerm_cognitive_account.ai[0].name
    private_connection_resource_id = azurerm_cognitive_account.ai[0].id
    is_manual_connection           = false
    subresource_names = [
      "account"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.ai[each.value.virtualNetworkKey].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.ai[0].id
    ]
  }
}
