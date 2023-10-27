terraform {
  required_version = ">= 1.6.2"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.78.0"
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

resource azurerm_resource_group express_route {
  name     = var.resourceGroupName
  location = var.regionName
}
