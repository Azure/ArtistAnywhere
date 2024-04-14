terraform {
  required_version = ">= 1.8.0"
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

variable resourceGroupName {
  type = string
}

variable regionName {
  type = string
}

variable virtualNetwork {
  type = object({
    name              = string
    resourceGroupName = string
  })
}

data azurerm_client_config studio {}

resource azurerm_resource_group network {
  name     = var.resourceGroupName
  location = var.regionName
}
