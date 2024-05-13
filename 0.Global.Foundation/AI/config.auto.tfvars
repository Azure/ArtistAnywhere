####################################################################################
# AI Services (https://learn.microsoft.com/azure/ai-services/what-are-ai-services) #
####################################################################################

ai = {
  bot = {
    enable        = false
    name          = "xstudio"
    displayName   = ""
    tier          = "S1"
    applicationId = ""
  }
  video = {
    enable = true
    name   = "xstudio"
  }
  open = {
    enable     = false
    name       = "xstudio-open"
    tier       = "S0"
    domainName = ""
  }
  cognitive = {
    enable     = true
    name       = "xstudio"
    tier       = "S0"
    domainName = ""
  }
  speech = {
    enable     = true
    name       = "xstudio-speech"
    tier       = "S0"
    domainName = ""
  }
  language = {
    conversational = {
      enable     = true
      name       = "xstudio-language-conversational"
      tier       = "S"
      domainName = ""
    }
    textAnalytics = {
      enable     = true
      name       = "xstudio-text-analytics"
      tier       = "S"
      domainName = ""
    }
    textTranslation = {
      enable     = true
      name       = "xstudio-text-translation"
      tier       = "S1"
      domainName = ""
    }
  }
  vision = {
    enable     = true
    name       = "xstudio-vision"
    tier       = "S1"
    domainName = ""
    training = {
      enable     = true
      name       = "xstudio-vision-training"
      tier       = "S0"
      domainName = ""
    }
    prediction = {
      enable     = true
      name       = "xstudio-vision-prediction"
      tier       = "S0"
      domainName = ""
    }
  }
  face = {
    enable     = true
    name       = "xstudio-face"
    tier       = "S0"
    domainName = ""
  }
  document = {
    enable     = true
    name       = "xstudio-document"
    tier       = "S0"
    domainName = ""
  }
  search = {
    enable         = false
    name           = "xstudio"
    tier           = "standard"
    hostingMode    = "default"
    replicaCount   = 1
    partitionCount = 1
    sharedPrivateAccess = {
      enable = false
    }
  }
  contentSafety = {
    enable     = true
    name       = "xstudio-content-safety"
    tier       = "S0"
    domainName = ""
  }
  immersiveReader = {
    enable     = true
    name       = "xstudio-immersive-reader"
    tier       = "S0"
    domainName = ""
  }
  machineLearning = {
    enable = false
    workspace = {
      name = "xstudio"
      tier = "Default"
    }
  }
  encryption = {
    enable = false
  }
}
