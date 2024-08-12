resourceGroupName = "ArtistAnywhere.App" # Alphanumeric, underscores, hyphens, periods and parenthesis are allowed

#################################################################
# Functions (https://learn.microsoft.com/azure/azure-functions) #
#################################################################

functionApp = {
  enable = true
  name   = "xstudio" # Set to a globally unique name (alphanumeric, hyphens)
  servicePlan = {
    type = "FC1"
    tier = "FlexConsumption" # https://learn.microsoft.com/azure/azure-functions/flex-consumption-plan
  }
  runtime = {
    name    = "dotnet-isolated"
    version = "8.0"
  }
  scale = {
    instance = {
      memoryMB = 2048
      maxCount = 40
    }
  }
}

#################################################################################################
# API Management (https://learn.microsoft.com/azure/api-management/api-management-key-concepts) #
#################################################################################################

apiManagement = {
  enable = false
  name   = "xstudio" # Set to a globally unique name (alphanumeric, hyphens)
  tier   = "Developer_1"
  publisher = {
    name  = ""
    email = ""
  }
  externalAccess = {
    enable = false
  }
}
