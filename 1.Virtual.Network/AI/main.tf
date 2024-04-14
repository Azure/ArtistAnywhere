terraform {
  required_version = ">= 1.8.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.99.0"
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
    name       = string
    tier       = string
    domainName = string
    open = object({
      name       = string
      tier       = string
      domainName = string
    })
    speech = object({
      name       = string
      tier       = string
      domainName = string
    })
    text = object({
      analytics = object({
        name       = string
        tier       = string
        domainName = string
      })
      translator = object({
        name       = string
        tier       = string
        domainName = string
      })
    })
    vision = object({
      name       = string
      tier       = string
      domainName = string
      custom = object({
        training = object({
          name       = string
          tier       = string
          regionName = string
          domainName = string
        })
        prediction = object({
          name       = string
          tier       = string
          regionName = string
          domainName = string
        })
      })
    })
    face = object({
      name       = string
      tier       = string
      domainName = string
    })
    document = object({
      name       = string
      tier       = string
      domainName = string
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

data terraform_remote_state network {
  backend = "azurerm"
  config = {
    resource_group_name  = module.global.resourceGroupName
    storage_account_name = module.global.storage.accountName
    container_name       = module.global.storage.containerName.terraformState
    key                  = "1.Virtual.Network"
  }
}

locals {
  virtualNetworks              = data.terraform_remote_state.network.outputs.virtualNetworks
  virtualNetworksSubnetCompute = data.terraform_remote_state.network.outputs.virtualNetworksSubnetCompute
}

resource azurerm_resource_group ai {
  name     = "${module.global.resourceGroupName}.AI"
  location = module.global.resourceLocation.region
}

resource azurerm_cognitive_account ai {
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
    ip_rules = [
      jsondecode(data.http.client_address.response_body).ip
    ]
  }
}

resource azurerm_private_dns_zone ai {
  name                = "privatelink.cognitiveservices.azure.com"
  resource_group_name = azurerm_resource_group.ai.name
}

resource azurerm_private_dns_zone_virtual_network_link ai {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.name => virtualNetwork
  }
  name                  = "${lower(each.value.name)}-ai"
  resource_group_name   = azurerm_private_dns_zone.ai.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.ai.name
  virtual_network_id    = each.value.id
}

resource azurerm_private_endpoint ai {
  for_each = {
    for subnet in local.virtualNetworksSubnetCompute : subnet.key => subnet
  }
  name                = "${lower(each.value.virtualNetworkName)}-ai"
  resource_group_name = each.value.resourceGroupName
  location            = each.value.regionName
  subnet_id           = "${each.value.virtualNetworkId}/subnets/${each.value.name}"
  private_service_connection {
    name                           = azurerm_cognitive_account.ai.name
    private_connection_resource_id = azurerm_cognitive_account.ai.id
    is_manual_connection           = false
    subresource_names = [
      "account"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.ai[each.value.virtualNetworkName].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.ai.id
    ]
  }
}
