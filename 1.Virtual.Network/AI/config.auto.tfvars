####################################################################################
# AI Services (https://learn.microsoft.com/azure/ai-services/what-are-ai-services) #
####################################################################################

ai = {
  enable     = true
  name       = "xstudio"
  tier       = "S0"
  domainName = ""
  open = {
    enable     = false
    name       = "xstudio-open"
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
      regionName = "WestUS2"
      domainName = ""
    }
    prediction = {
      enable     = true
      name       = "xstudio-vision-prediction"
      tier       = "S0"
      regionName = "WestUS2"
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
  encryption = {
    enable = false
  }
}
