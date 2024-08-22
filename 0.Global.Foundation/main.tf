terraform {
  required_version = ">= 1.9.4"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.116.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>2.53.1"
    }
    http = {
      source  = "hashicorp/http"
      version = "~>3.4.4"
    }
    time = {
      source  = "hashicorp/time"
      version = "~>0.12.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~>4.0.5"
    }
    azapi = {
      source = "azure/azapi"
      version = "~>1.15.0"
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
    cognitive_account {
      purge_soft_delete_on_destroy = true
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
    machine_learning {
      purge_soft_deleted_workspace_on_destroy = true
    }
  }
  storage_use_azuread = true
}

module global {
  source = "./cfg"
}

data http client_address {
  url = "https://api.ipify.org?format=json"
}

data azurerm_client_config studio {}

locals {
  aiEnable = var.aiServices.enable || var.aiSearch.enable || var.aiMachineLearning.enable
}

resource azurerm_resource_group studio {
  name     = module.global.resourceGroupName
  location = module.global.resourceLocation.regionName
}

resource azurerm_resource_group studio_monitor {
  name     = "${module.global.resourceGroupName}.Monitor"
  location = module.global.resourceLocation.regionName
}

resource azurerm_resource_group studio_registry {
  count    = var.containerRegistry.enable ? 1 : 0
  name     = "${module.global.resourceGroupName}.Registry"
  location = module.global.resourceLocation.regionName
}

resource azurerm_resource_group studio_ai {
  count    = local.aiEnable ? 1 : 0
  name     = "${module.global.resourceGroupName}.AI"
  location = module.global.resourceLocation.regionName
}
