terraform {
  required_version = ">=1.11.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.27.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>3.3.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~>3.5.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~>0.13.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~>4.1.0"
    }
  }
}

provider azurerm {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id     = var.subscriptionId
  storage_use_azuread = true
}

variable subscriptionId {
  type = string
  validation {
    condition     = var.subscriptionId != ""
    error_message = "Azure subscriptionId is a required input variable in the 0.Core.Foundation\\config.auto.tfvars file."
  }
}

variable defaultLocation {
  type = string
  validation {
    condition     = var.defaultLocation != ""
    error_message = "Azure defaultLocation is a required input variable in the 0.Core.Foundation\\config.auto.tfvars file."
  }
}

locals {
  backendConfig = {
    patternSuffix = "\\s+=\\s+\"([^\"]+)"
  }
  resourceGroup = {
    name     = regex("resource_group_name${local.backendConfig.patternSuffix}", file("./config/backend"))[0]
    location = var.defaultLocation
  }
}

data http client_address {
  url = "https://api.ipify.org?format=json"
}

data azurerm_subscription current {}

data azurerm_client_config current {}

resource azurerm_resource_group studio {
  name     = local.resourceGroup.name
  location = var.defaultLocation
  tags = {
    AAA = basename(path.cwd)
  }
}

resource azurerm_resource_group studio_monitor {
  name     = "${azurerm_resource_group.studio.name}.Monitor"
  location = azurerm_resource_group.studio.location
  tags = {
    AAA = basename(path.cwd)
  }
}

output subscriptionId {
  value = data.azurerm_subscription.current.subscription_id
}

output defaultLocation {
  value = var.defaultLocation
}

output resourceGroup {
  value = local.resourceGroup
}
