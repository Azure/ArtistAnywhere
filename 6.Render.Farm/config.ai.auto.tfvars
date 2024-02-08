################################################################################
# Azure OpenAI (https://learn.microsoft.com/azure/ai-services/openai/overview) #
################################################################################

azureOpenAI = {
  enable      = false
  regionName  = "EastUS"
  accountName = "xstudio"
  domainName  = ""
  serviceTier = "S0"
  chatDeployment = {
    model = {
      name    = "gpt-35-turbo"
      format  = "OpenAI"
      version = ""
      scale   = "Standard"
    }
    session = {
      context = ""
      request = ""
    }
  }
  imageGeneration = {
    description = ""
    height      = 1024
    width       = 1024
  }
  storage = {
    enable = false
  }
}

#####################################################
# https://learn.microsoft.com/azure/azure-functions #
#####################################################

functionApp = {
  enable        = false
  name          = "xstudio"
  subnetName    = "AI"
  fileShareName = "content"
  servicePlan = {
    computeTier = "S1"
    workerCount = 2
    alwaysOn    = false
  }
}
