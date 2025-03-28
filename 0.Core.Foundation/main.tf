terraform {
  required_version = ">=1.11.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.24.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>3.2.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~>3.4.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~>4.0.0"
    }
  }
}

provider azurerm {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id     = var.subscription.id
  storage_use_azuread = true
}

module core {
  source = "./config"
}

variable subscription {
  type = object({
    id = string
  })
}

locals {
  patternSuffix = "\\s+=\\s+\"([^\"]+)"
  resourceGroup = {
    name     = regex("resource_group_name${local.patternSuffix}", file("./config/backend"))[0]
    location = module.core.resourceLocation.name
  }
  storage = {
    account = {
      name = regex("storage_account_name${local.patternSuffix}", file("./config/backend"))[0]
    }
    containerName = {
      terraformState = regex("container_name${local.patternSuffix}", file("./config/backend"))[0]
    }
  }
}

data http client_address {
  url = "https://api.ipify.org?format=json"
}

data azurerm_subscription current {}

data azurerm_client_config current {}

resource azurerm_resource_group studio {
  name     = local.resourceGroup.name
  location = module.core.resourceLocation.name
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

output subscription {
  value = {
    id = data.azurerm_subscription.current.subscription_id
  }
}

output resourceGroup {
  value = local.resourceGroup
}

output storage {
  value = local.storage
}
