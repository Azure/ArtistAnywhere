###############################################################################################
# Cosmos DB Apache Gremlin (https://learn.microsoft.com/azure/cosmos-db/gremlin/introduction) #
###############################################################################################

variable cosmosGremlin {
  type = object({
    enable = bool
    name   = string
  })
}
