terraform {
  required_version = ">=1.10.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.20.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>3.1.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~>3.4.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~>0.12.0"
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
    application_insights {
      disable_generated_rule = false
    }
    key_vault {
      purge_soft_delete_on_destroy                                = true
      purge_soft_deleted_secrets_on_destroy                       = true
      purge_soft_deleted_keys_on_destroy                          = true
      purge_soft_deleted_certificates_on_destroy                  = true
      purge_soft_deleted_hardware_security_modules_on_destroy     = true
      purge_soft_deleted_hardware_security_module_keys_on_destroy = true
      recover_soft_deleted_key_vaults                             = true
      recover_soft_deleted_secrets                                = true
      recover_soft_deleted_keys                                   = true
      recover_soft_deleted_certificates                           = true
      recover_soft_deleted_hardware_security_module_keys          = true
    }
    log_analytics_workspace {
      permanently_delete_on_destroy = false
    }
  }
  subscription_id     = module.global.subscriptionId
  storage_use_azuread = true
}

module global {
  source = "./config"
}

data http client_address {
  url = "https://api.ipify.org?format=json"
}

data azurerm_subscription current {}

data azurerm_client_config current {}

resource azurerm_resource_group studio {
  name     = module.global.resourceGroupName
  location = module.global.resourceLocation.regionName
  tags = {
    AAA = basename(path.cwd)
  }
}

resource azurerm_resource_group studio_message {
  name     = "${azurerm_resource_group.studio.name}.Message"
  location = azurerm_resource_group.studio.location
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
