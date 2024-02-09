########################################################################
# Cosmos DB (https://learn.microsoft.com/azure/cosmos-db/introduction) #
########################################################################

cosmosDB = {
  enable = false
  account = {
    name             = "xstudio"
    offerType        = "Standard"
    consistencyLevel = "Strong"
  }
  database = {
    name       = "Deadline"
    throughput = 400
  }
}
