terraform {
  required_version = ">= 1.8.1"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.99.0"
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

variable regionName {
  type = string
}

variable resourceGroupName {
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

data azurerm_client_config studio {}

resource azurerm_resource_group network {
  name     = var.resourceGroupName
  location = var.regionName
}
