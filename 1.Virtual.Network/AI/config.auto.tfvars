####################################################################################
# AI Services (https://learn.microsoft.com/azure/ai-services/what-are-ai-services) #
####################################################################################

ai = {
  name       = "xstudio"
  tier       = "S0"
  domainName = ""
  open = {
    name       = "xstudio-open"
    tier       = "S0"
    domainName = ""
  }
  speech = {
    name       = "xstudio-speech"
    tier       = "S0"
    domainName = ""
  }
  text = {
    analytics = {
      name       = "xstudio-text-analytics"
      tier       = "S"
      domainName = ""
    }
    translator = {
      name       = "xstudio-text-translator"
      tier       = "S1"
      domainName = ""
    }
  }
  vision = {
    name       = "xstudio-vision"
    tier       = "S1"
    domainName = ""
    custom = {
      training = {
        name       = "xstudio-vision-training"
        tier       = "S0"
        regionName = "WestUS2"
        domainName = ""
      }
      prediction = {
        name       = "xstudio-vision-prediction"
        tier       = "S0"
        regionName = "WestUS2"
        domainName = ""
      }
    }
  }
  face = {
    name       = "xstudio-face"
    tier       = "S0"
    domainName = ""
  }
  document = {
    name       = "xstudio-document"
    tier       = "S0"
    domainName = ""
  }
}
