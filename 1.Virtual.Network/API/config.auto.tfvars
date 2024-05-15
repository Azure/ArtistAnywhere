resourceGroupName = "ArtistAnywhere.API" # Alphanumeric, underscores, hyphens, periods and parenthesis are allowed

################################################################################################
# API Management (https://learn.microsoft.com/azure/api-management/api-management-key-concepts #
################################################################################################

apiManagement = {
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
