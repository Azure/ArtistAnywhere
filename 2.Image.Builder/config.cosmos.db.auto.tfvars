########################################################################
# Cosmos DB (https://learn.microsoft.com/azure/cosmos-db/introduction) #
########################################################################

cosmosDB = {
  enable     = false
  name       = "xstudio"
  tier       = "M30"
  version    = "5.0"
  nodeCount  = 1
  diskSizeGB = 128
  highAvailability = {
    enable = false
  }
}
