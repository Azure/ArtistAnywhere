resourceGroupName = "ArtistAnywhere.Docker" # Alphanumeric, underscores, hyphens, periods and parenthesis are allowed

######################################################################################################
# Container Registry (https://learn.microsoft.com/azure/container-registry/container-registry-intro) #
######################################################################################################

containerRegistry = {
  name = "xstudio"
  type = "Premium"
  adminUser = {
    enable = true
  }
  tasks = {
    enable = false
  }
}

#######################################################################
# Resource dependency configuration for pre-existing deployments only #
#######################################################################

existingNetwork = {
  enable            = false
  name              = ""
  subnetName        = ""
  resourceGroupName = ""
}
