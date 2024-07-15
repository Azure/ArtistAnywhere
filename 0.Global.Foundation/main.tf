terraform {
  required_version = ">= 1.9.2"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.112.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>2.53.1"
    }
    http = {
      source  = "hashicorp/http"
      version = "~>3.4.3"
    }
    time = {
      source  = "hashicorp/time"
      version = "~>0.11.2"
    }
    azapi = {
      source = "azure/azapi"
      version = "~>1.14.0"
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
    app_configuration {
      purge_soft_delete_on_destroy = true
      recover_soft_deleted         = true
    }
    key_vault {
      purge_soft_delete_on_destroy                            = true
      purge_soft_deleted_secrets_on_destroy                   = true
      purge_soft_deleted_keys_on_destroy                      = true
      purge_soft_deleted_certificates_on_destroy              = true
      purge_soft_deleted_hardware_security_modules_on_destroy = true
      recover_soft_deleted_key_vaults                         = true
      recover_soft_deleted_secrets                            = true
      recover_soft_deleted_keys                               = true
      recover_soft_deleted_certificates                       = true
    }
    log_analytics_workspace {
      permanently_delete_on_destroy = true
    }
  }
}

module global {
  source = "./config"
}

data http client_address {
  url = "https://api.ipify.org?format=json"
}

data azurerm_client_config studio {}

resource azurerm_resource_group studio {
  name     = module.global.resourceGroupName
  location = module.global.resourceLocation.regionName
}
