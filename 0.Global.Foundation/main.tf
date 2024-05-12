terraform {
  required_version = ">= 1.8.2"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.102.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>2.49.0"
    }
    azapi = {
      source = "azure/azapi"
      version = "~>1.13.1"
    }
    http = {
      source  = "hashicorp/http"
      version = "~>3.4.2"
    }
    time = {
      source  = "hashicorp/time"
      version = "~>0.11.1"
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

variable ai {
  type = object({
    video = object({
      enable = bool
      name   = string
    })
    open = object({
      enable     = bool
      name       = string
      tier       = string
      domainName = string
    })
    cognitive = object({
      enable     = bool
      name       = string
      tier       = string
      domainName = string
    })
    speech = object({
      enable     = bool
      name       = string
      tier       = string
      domainName = string
    })
    language = object({
      conversational = object({
        enable     = bool
        name       = string
        tier       = string
        domainName = string
      })
      textAnalytics = object({
        enable     = bool
        name       = string
        tier       = string
        domainName = string
      })
      textTranslation = object({
        enable     = bool
        name       = string
        tier       = string
        domainName = string
      })
    })
    vision = object({
      enable     = bool
      name       = string
      tier       = string
      domainName = string
      training = object({
        enable     = bool
        name       = string
        tier       = string
        domainName = string
      })
      prediction = object({
        enable     = bool
        name       = string
        tier       = string
        domainName = string
      })
    })
    face = object({
      enable     = bool
      name       = string
      tier       = string
      domainName = string
    })
    document = object({
      enable     = bool
      name       = string
      tier       = string
      domainName = string
    })
    search = object({
      enable         = bool
      name           = string
      tier           = string
      hostingMode    = string
      replicaCount   = number
      partitionCount = number
      sharedPrivateAccess = object({
        enable = bool
      })
    })
    machineLearning = object({
      enable = bool
      workspace = object({
        name = string
        tier = string
      })
    })
    encryption = object({
      enable = bool
    })
  })
}

data http client_address {
  url = "https://api.ipify.org?format=json"
}

data azurerm_client_config studio {}

resource azurerm_resource_group studio {
  name     = module.global.resourceGroupName
  location = module.global.resourceLocation.regionName
}

resource azurerm_resource_group studio_ai {
  count    = module.global.ai.enable ? 1 : 0
  name     = "${azurerm_resource_group.studio.name}.AI"
  location = azurerm_resource_group.studio.location
}
