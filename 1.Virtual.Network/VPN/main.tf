terraform {
  required_version = ">= 1.8.4"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.104.0"
    }
  }
}

provider azurerm {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

variable virtualNetwork {
  type = object({
    name              = string
    edgeZoneName      = string
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

data azurerm_client_config studio {}

data azurerm_resource_group network {
  name = var.virtualNetwork.resourceGroupName
}
