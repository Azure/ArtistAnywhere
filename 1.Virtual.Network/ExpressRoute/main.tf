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
  })
}

resource azurerm_resource_group express_route {
  name     = var.resourceGroupName
  location = var.regionName
}
