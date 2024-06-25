terraform {
  required_version = ">= 1.8.4"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.109.0"
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
      version = "~>1.13.1"
    }
  }
  backend azurerm {
    key = "0.Global.Foundation.AI"
  }
}

provider azurerm {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

module global {
  source = "../config"
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
    contentSafety = object({
      enable     = bool
      name       = string
      tier       = string
      domainName = string
    })
    immersiveReader = object({
      enable     = bool
      name       = string
      tier       = string
      domainName = string
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

data azurerm_user_assigned_identity studio {
  name                = module.global.managedIdentity.name
  resource_group_name = module.global.resourceGroupName
}

data azurerm_storage_account studio {
  name                = module.global.storage.accountName
  resource_group_name = module.global.resourceGroupName
}

data azurerm_key_vault studio {
  count               = module.global.keyVault.enable ? 1 : 0
  name                = module.global.keyVault.name
  resource_group_name = module.global.resourceGroupName
}

data azurerm_key_vault_key data_encryption {
  count        = module.global.keyVault.enable ? 1 : 0
  name         = module.global.keyVault.keyName.dataEncryption
  key_vault_id = data.azurerm_key_vault.studio[0].id
}

data azurerm_application_insights studio {
  count               = module.global.monitor.enable ? 1 : 0
  name                = module.global.monitor.name
  resource_group_name = module.global.resourceGroupName
}

resource azurerm_resource_group studio_ai {
  name     = "${module.global.resourceGroupName}.AI"
  location = module.global.resourceLocation.regionName
}

output ai {
  value = {
    resourceGroupName = azurerm_resource_group.studio_ai.name
    regionName        = azurerm_resource_group.studio_ai.location
    video = {
      enable = var.ai.video.enable
      id     = var.ai.video.enable ? azapi_resource.ai_video_indexer[0].id : null
      name   = var.ai.video.enable ? azapi_resource.ai_video_indexer[0].name : null
    }
    open = {
      enable = var.ai.open.enable
      id     = var.ai.open.enable ? azurerm_cognitive_account.ai_open[0].id : null
      name   = var.ai.open.enable ? azurerm_cognitive_account.ai_open[0].name : null
    }
    cognitive = {
      enable = var.ai.cognitive.enable
      id     = var.ai.cognitive.enable ? azurerm_cognitive_account.ai[0].id : null
      name   = var.ai.cognitive.enable ? azurerm_cognitive_account.ai[0].name : null
    }
    speech = {
      enable = var.ai.speech.enable
      id     = var.ai.speech.enable ? azurerm_cognitive_account.ai_speech[0].id : null
      name   = var.ai.speech.enable ? azurerm_cognitive_account.ai_speech[0].name : null
    }
    language = {
      conversational = {
        enable = var.ai.language.conversational.enable
        id     = var.ai.language.conversational.enable ? azurerm_cognitive_account.ai_language_conversational[0].id : null
        name   = var.ai.language.conversational.enable ? azurerm_cognitive_account.ai_language_conversational[0].name : null
      }
      textAnalytics = {
        enable = var.ai.language.textAnalytics.enable
        id     = var.ai.language.textAnalytics.enable ? azurerm_cognitive_account.ai_language_text_analytics[0].id : null
        name   = var.ai.language.textAnalytics.enable ? azurerm_cognitive_account.ai_language_text_analytics[0].name : null
      }
      textTranslation = {
        enable = var.ai.language.textTranslation.enable
        id     = var.ai.language.textTranslation.enable ? azurerm_cognitive_account.ai_language_text_translation[0].id : null
        name   = var.ai.language.textTranslation.enable ? azurerm_cognitive_account.ai_language_text_translation[0].name : null
      }
    }
    vision = {
      enable = var.ai.vision.enable
      id     = var.ai.vision.enable ? azurerm_cognitive_account.ai_vision[0].id : null
      name   = var.ai.vision.enable ? azurerm_cognitive_account.ai_vision[0].name : null
      training = {
        enable = var.ai.vision.training.enable
        id     = var.ai.vision.training.enable ? azurerm_cognitive_account.ai_vision_training[0].id : null
        name   = var.ai.vision.training.enable ? azurerm_cognitive_account.ai_vision_training[0].name : null
      }
      prediction = {
        enable = var.ai.vision.prediction.enable
        id     = var.ai.vision.prediction.enable ? azurerm_cognitive_account.ai_vision_prediction[0].id : null
        name   = var.ai.vision.prediction.enable ? azurerm_cognitive_account.ai_vision_prediction[0].name : null
      }
    }
    face = {
      enable = var.ai.face.enable
      id     = var.ai.face.enable ? azurerm_cognitive_account.ai_face[0].id : null
      name   = var.ai.face.enable ? azurerm_cognitive_account.ai_face[0].name : null
    }
    document = {
      enable = var.ai.document.enable
      id     = var.ai.document.enable ? azurerm_cognitive_account.ai_document[0].id : null
      name   = var.ai.document.enable ? azurerm_cognitive_account.ai_document[0].name : null
    }
    search = {
      enable = var.ai.search.enable
      id     = var.ai.search.enable ? azurerm_search_service.ai[0].id : null
      name   = var.ai.search.enable ? azurerm_search_service.ai[0].name : null
    }
    contentSafety = {
      enable = var.ai.contentSafety.enable
      id     = var.ai.contentSafety.enable ? azurerm_cognitive_account.ai_content_safety[0].id : null
      name   = var.ai.contentSafety.enable ? azurerm_cognitive_account.ai_content_safety[0].name : null
    }
    immersiveReader = {
      enable = var.ai.immersiveReader.enable
      id     = var.ai.immersiveReader.enable ? azurerm_cognitive_account.ai_immersive_reader[0].id : null
      name   = var.ai.immersiveReader.enable ? azurerm_cognitive_account.ai_immersive_reader[0].name : null
    }
    machineLearning = {
      enable = var.ai.machineLearning.enable
      id     = var.ai.machineLearning.enable ? azurerm_machine_learning_workspace.ai[0].id : null
      name   = var.ai.machineLearning.enable ? azurerm_machine_learning_workspace.ai[0].name : null
    }
  }
}
