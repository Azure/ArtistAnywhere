resourceGroupName = "ArtistAnywhere.Database" # Alphanumeric, underscores, hyphens, periods and parenthesis are allowed

########################################################################
# Cosmos DB (https://learn.microsoft.com/azure/cosmos-db/introduction) #
########################################################################

cosmosDB = {
  accountName = "xstudio"
  offerType   = "Standard"
  dataConsistency = {
    policyLevel        = "Session"
    maxIntervalSeconds = 5
    maxStalenessPrefix = 100
  }
  serverless = {
    enable = true
  }
  aggregationPipeline = {
    enable = true
  }
  analyticalStorage = {
    enable     = true
    schemaType = ""
  }
  secondaryEncryption = {
    enable  = true
    keyName = ""
  }
  automaticFailover = {
    enable = true
  }
  partitionMerge = {
    enable = false
  }
  multiRegionWrite = {
    enable = false
  }
}

########################################################################
# Cosmos DB NoSQL (https://learn.microsoft.com/azure/cosmos-db/nosql/) #
########################################################################

cosmosNoSQL = {
  enable = true
  name   = "xstudio"
  database = {
    enable     = false
    name       = "Studio"
    throughput = null
    containers = [
      {
        enable     = false
        name       = ""
        throughput = null
        partitionKey = {
          path    = ""
          version = 2
        }
        storedProcedures = [
          {
            enable = false
            name   = "helloCosmos"
            body   = <<BODY
              function () {
                var context = getContext()
                var response = context.getResponse()
                response.setBody("Hello Cosmos!")
              }
            BODY
          }
        ]
        triggers = [
          {
            enable    = false
            name      = ""
            type      = "" # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cosmosdb_sql_trigger#type
            operation = "" # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cosmosdb_sql_trigger#operation
            body      = ""
          }
        ]
        functions = [
          {
            enable = false
            name   = ""
            body   = ""
          }
        ]
      }
    ]
  }
  gateway = {
    enable = false
    size   = "Cosmos.D4s"
    count  = 1
  }
}

###############################################################################################
# Cosmos DB Mongo DB    (https://learn.microsoft.com/azure/cosmos-db/mongodb/introduction)    #
# Cosmos DB Mongo DB RU (https://learn.microsoft.com/azure/cosmos-db/mongodb/ru/introduction) #
###############################################################################################

cosmosMongoDB = {
  enable  = false
  name    = "xstudio"
  version = "4.2"
  database = {
    enable     = false
    name       = "Studio"
    throughput = null
  }
}

#####################################################################################################
# Cosmos DB Mongo DB vCore (https://learn.microsoft.com/azure/cosmos-db/mongodb/vcore/introduction) #
#####################################################################################################

cosmosMongoDBvCore = {
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

###################################################################################################
# Cosmos DB Apache Cassandra (https://learn.microsoft.com/azure/cosmos-db/cassandra/introduction) #
###################################################################################################

cosmosCassandra = {
  enable = false
  name   = "xstudio"
}

########################################################################################################################
# Apache Cassandra Managed Instance (https://learn.microsoft.com/azure/managed-instance-apache-cassandra/introduction) #
########################################################################################################################

apacheCassandra = {
  enable  = false
  name    = "xstudio"
  version = "4.0"
  datacenter = {
    name = "dc0"
    node = {
      type  = "Standard_E16s_v5"
      count = 3
      disk = {
        type  = "P30"
        count = 2
      }
    }
  }
  backup = {
    intervalHours = 24
  }
}

##############################################################################################
# Cosmos DB PostgreSQL (https://learn.microsoft.com/azure/cosmos-db/postgresql/introduction) #
##############################################################################################

cosmosPostgreSQL = {
  enable       = false
  name         = "xstudio"
  version      = "16"
  versionCitus = "12.1"
  worker = {
    serverEdition = "MemoryOptimized"
    storageMB     = 524288
    coreCount     = 2
    nodeCount     = 0
  }
  coordinator = {
    serverEdition = "GeneralPurpose"
    storageMB     = 131072
    coreCount     = 2
    shards = {
      enable = true
    }
  }
  highAvailability = {
    enable = false
  }
  maintenanceWindow = {
    enable      = false
    dayOfWeek   = 0
    startHour   = 0
    startMinute = 0
  }
}

###############################################################################################
# Cosmos DB Apache Gremlin (https://learn.microsoft.com/azure/cosmos-db/gremlin/introduction) #
###############################################################################################

cosmosGremlin = {
  enable = false
  name   = "xstudio"
  database = {
    enable     = false
    name       = "Studio"
    throughput = null
  }
}

####################################################################################
# Cosmos DB Table (https://learn.microsoft.com/azure/cosmos-db/table/introduction) #
####################################################################################

cosmosTable = {
  enable = false
  name   = "xstudio"
}

#######################################################################
# Resource dependency configuration for pre-existing deployments only #
#######################################################################

existingKeyVault = {
  enable            = false
  name              = ""
  resourceGroupName = ""
}

existingNetwork = {
  enable            = false
  name              = ""
  subnetNameData    = ""
  subnetNameFarm    = ""
  resourceGroupName = ""
}
