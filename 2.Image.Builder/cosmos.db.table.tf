####################################################################################
# Cosmos DB Table (https://learn.microsoft.com/azure/cosmos-db/table/introduction) #
####################################################################################

variable cosmosTable {
  type = object({
    enable = bool
    name   = string
  })
}
