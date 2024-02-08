resourceGroupName = "ArtistAnywhere.Farm" # Alphanumeric, underscores, hyphens, periods and parenthesis are allowed

#######################################################################
# Resource dependency configuration for pre-existing deployments only #
#######################################################################

activeDirectory = {
  enable           = false
  domainName       = "artist.studio"
  domainServerName = "WinScheduler"
  orgUnitPath      = ""
  adminUsername    = ""
  adminPassword    = ""
}

existingNetwork = {
  enable            = false
  name              = ""
  subnetNameFarm    = ""
  subnetNameAI      = ""
  resourceGroupName = ""
}

existingStorage = {
  enable            = false
  name              = ""
  resourceGroupName = ""
  fileShareName     = ""
}
