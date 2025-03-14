terraform {
  required_version = ">=1.11.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.23.0"
    }
  }
}

provider azurerm {
  features {
  }
  subscription_id = var.subscriptionId
}

variable subscriptionId {
  type = string
}

variable virtualNetwork {
  type = object({
    name              = string
    resourceGroupName = string
    gateway = object({
      ipAddress1 = object({
        name              = string
        resourceGroupName = string
      })
      ipAddress2 = object({
        name              = string
        resourceGroupName = string
      })
    })
  })
}

data azurerm_virtual_network studio {
  name                = var.virtualNetwork.name
  resource_group_name = var.virtualNetwork.resourceGroupName
}

data azurerm_subnet gateway {
  name                 = "GatewaySubnet"
  resource_group_name  = data.azurerm_virtual_network.studio.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.studio.name
}

data azurerm_public_ip gateway1 {
  name                = var.virtualNetwork.gateway.ipAddress1.name
  resource_group_name = var.virtualNetwork.gateway.ipAddress1.resourceGroupName
}

data azurerm_public_ip gateway2 {
  count               = var.virtualNetwork.gateway.ipAddress2.name != "" ? 1 : 0
  name                = var.virtualNetwork.gateway.ipAddress2.name
  resource_group_name = var.virtualNetwork.gateway.ipAddress2.resourceGroupName
}
