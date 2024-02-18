########################################################################
# Cosmos DB (https://learn.microsoft.com/azure/cosmos-db/introduction) #
########################################################################

cosmosDB = {
  tier = "Standard"
  consistency = {
    policyLevel        = "Strong"
    maxIntervalSeconds = 5
    maxStalenessPrefix = 100
  }
  customEncryption = {
    enable  = false
    keyName = ""
  }
  partitionMerge = {
    enable = false
  }
  aggregationPipeline = {
    enable = false
  }
  automaticFailover = {
    enable = false
  }
  analytics = {
    enable     = false
    schemaType = "FullFidelity"
  }
}

########################################################################
# Cosmos DB NoSQL (https://learn.microsoft.com/azure/cosmos-db/nosql/) #
########################################################################

cosmosNoSQL = {
  enable = false
  name   = "xstudio"
  dedicatedGateway = {
    enable = false
    size   = "Cosmos.D4s"
    count  = 1
  }
}

#####################################################################################################
# Cosmos DB Mongo DB       (https://learn.microsoft.com/azure/cosmos-db/mongodb/introduction)       #
# Cosmos DB Mongo DB RU    (https://learn.microsoft.com/azure/cosmos-db/mongodb/ru/introduction)    #
# Cosmos DB Mongo DB vCore (https://learn.microsoft.com/azure/cosmos-db/mongodb/vcore/introduction) #
#####################################################################################################

cosmosMongoDB = {
  enable  = false
  name    = "xstudio"
  version = "4.2"
  database = {
    name       = "deadline10db"
    throughput = 400
  }
  vCore = {
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
}

########################################################################################################################
# Cosmos DB Apache Cassandra RU     (https://learn.microsoft.com/azure/cosmos-db/cassandra/introduction)               #
# Apache Cassandra Managed Instance (https://learn.microsoft.com/azure/managed-instance-apache-cassandra/introduction) #
########################################################################################################################

cosmosCassandra = {
  enable  = false
  name    = "xstudio"
  managedInstance = {
    enable  = false
    name    = "xstudio"
    version = "4.0"
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
}

####################################################################################
# Cosmos DB Table (https://learn.microsoft.com/azure/cosmos-db/table/introduction) #
####################################################################################

cosmosTable = {
  enable = false
  name   = "xstudio"
}
