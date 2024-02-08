resourceGroupName = "ArtistAnywhere.Storage" # Alphanumeric, underscores, hyphens, periods and parenthesis are allowed

fileLoadSource = { # Applies to Storage and Weka only
  enable        = false
  accountName   = ""
  accountKey    = ""
  containerName = ""
  blobName      = ""
}

#######################################################################
# Resource dependency configuration for pre-existing deployments only #
#######################################################################

existingNetwork = {
  enable             = false
  name               = ""
  subnetName         = ""
  resourceGroupName  = ""
  privateDnsZoneName = ""
  serviceEndpointSubnets = [ # https://learn.microsoft.com/azure/storage/common/storage-network-security#grant-access-from-a-virtual-network
    {
      name               = ""
      virtualNetworkName = ""
    }
  ]
}
