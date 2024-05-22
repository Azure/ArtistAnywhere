resourceGroupName = "ArtistAnywhere.Data" # Alphanumeric, underscores, hyphens, periods and parenthesis are allowed

data = {
  lake = {
    paths = [
      "synapse",
      "databricks"
    ]
    storageAccount = {
      name        = "xstudio1"
      type        = "StorageV2"
      redundancy  = "LRS"
      performance = "Standard"
    }
  }
  factory = {
    enable = true
    name   = "xstudio"
    encryption = {
      enable = false
    }
  }
  analytics = {
    cosmosDB = {
      enable     = true
      schemaType = "FullFidelity" # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cosmosdb_account#schema_type
    }
    synapse = {
      enable = true
    }
    databricks = {
      enable = true
      serverless = {
        enable = true
      }
      workspace = {
        tier = "standard"
      }
      storageAccount = {
        name = "xstudio4"
        type = "Standard_LRS"
      }
    }
    stream = {
      enable = false
      cluster = {
        name = "xstudio"
        size = 120
      }
    }
    workspace = {
      name = "xstudio"
      adminLogin = {
        userName     = "xadmin"
        userPassword = "P@ssword1234"
      }
      encryption = {
        enable = false
      }
    }
  }
  governance = {
    enable = false
    name   = "xstudio"
  }
}

########################################################################
# Cosmos DB (https://learn.microsoft.com/azure/cosmos-db/introduction) #
########################################################################

cosmosDB = {
  tier = "Standard"
  serverless = {
    enable = true
  }
  geoLocations = [
    {
      enable     = true
      regionName = "WestUS2"
      failover = {
        priority = 0
      }
      zoneRedundant = {
        enable = false
      }
    },
    {
      enable     = false
      regionName = "EastUS"
      failover = {
        priority = 1
      }
      zoneRedundant = {
        enable = false
      }
    }
  ]
  dataConsistency = {
    policyLevel = "Session" # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cosmosdb_account#consistency_level
    maxStaleness = {
      intervalSeconds = 5
      itemUpdateCount = 100
    }
  }
  aggregationPipeline = {
    enable = false
  }
  automaticFailover = {
    enable = false
  }
  multiRegionWrite = {
    enable = false
  }
  partitionMerge = {
    enable = false
  }
  encryption = {
    enable = false
  }
  backup = {
    type              = "Periodic"
    tier              = null
    retentionHours    = 8
    intervalMinutes   = 240
    storageRedundancy = "Geo"
  }
}

#######################################################################
# Cosmos DB NoSQL (https://learn.microsoft.com/azure/cosmos-db/nosql) #
#######################################################################

noSQL = {
  enable = true
  account = {
    name = "xstudio"
    accessKeys = {
      enable = true
    }
    dedicatedGateway = {
      enable = false
      size   = "Cosmos.D4s"
      count  = 1
    }
  }
  databases = [
    {
      enable = true
      name   = "Media"
      throughput = {
        requestUnits = null
        autoScale = {
          enable = false
        }
      }
      containers = [
        {
          enable = true
          name   = "Content"
          throughput = {
            requestUnits = null
            autoScale = {
              enable = false
            }
          }
          partitionKey = {
            version = 2
            paths = [
             "/tenantId"
            ]
          }
          # geospatial = {
          #   type = "Geography"
          # }
          indexPolicy = {
            mode = "consistent"
            includedPaths = [
              "/*"
            ]
            excludedPaths = [
            ]
            composite = [
              {
                enable = false
                paths = [
                  {
                    enable = false
                    path   = ""
                    order  = "Ascending"
                  }
                ]
              }
            ]
            spatial = [
              {
                enable = false
                path   = ""
              }
            ]
          }
          storedProcedures = [
            {
              enable = false
              name   = "helloCosmos"
              body   = <<BODY
                function () {
                  var context = getContext();
                  var response = context.getResponse();
                  response.setBody("Hello Cosmos!");
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
          timeToLive = {
            default   = null
            analytics = null
          }
          conflictResolutionPolicy = {
            mode      = "LastWriterWins"
            path      = "/_ts"
            procedure = ""
          }
        }
      ]
    }
  ]
  roles = [
    {
      enable = false
      name   = "Account Reader"
      scopePaths = [
        ""
      ]
      permissions = [
        "Microsoft.DocumentDB/databaseAccounts/readMetadata"
      ]
    }
  ]
  roleAssignments = [
    {
      enable      = true
      name        = ""
      scopePath   = ""
      principalId = "5a5ba375-541b-4c18-8e61-087decdc29cf"
      role = {
        id   = "00000000-0000-0000-0000-000000000002" # Cosmos DB Built-in Data Contributor
        name = ""
      }
    }
  ]
}

###############################################################################################
# Cosmos DB Mongo DB    (https://learn.microsoft.com/azure/cosmos-db/mongodb/introduction)    #
# Cosmos DB Mongo DB RU (https://learn.microsoft.com/azure/cosmos-db/mongodb/ru/introduction) #
###############################################################################################

mongoDB = {
  enable = false
  account = {
    name    = "xstudio"
    version = "4.2"
  }
  databases = [
    {
      enable     = false
      name       = "Media1"
      throughput = null
      collections = [
        {
          enable     = false
          name       = ""
          shardKey   = null
          throughput = null
          indices = [
            {
              enable = true
              unique = true
              keys = [
                "_id"
              ]
            }
          ]
        }
      ]
      roles = [
        {
          enable    = false
          name      = ""
          roleNames = [
          ]
          privileges = [
            {
              enable = false
              resource = {
                databaseName   = ""
                collectionName = ""
              }
              actions = [
              ]
            }
          ]
        }
      ]
      users = [
        {
          enable    = false
          username  = ""
          password  = ""
          roleNames = [
          ]
        }
      ]
    }
  ]
}

#####################################################################################################
# Cosmos DB Mongo DB vCore (https://learn.microsoft.com/azure/cosmos-db/mongodb/vcore/introduction) #
#####################################################################################################

mongoDBvCore = {
  enable = false
  cluster = {
    name    = "xstudio"
    tier    = "M30"
    version = "6.0"
    adminLogin = {
      userName     = "xadmin"
      userPassword = "P@ssword1234"
    }
  }
  node = {
    count      = 1
    diskSizeGB = 128
  }
  highAvailability = {
    enable = false
  }
}

##############################################################################################
# Cosmos DB PostgreSQL (https://learn.microsoft.com/azure/cosmos-db/postgresql/introduction) #
##############################################################################################

postgreSQL = {
  enable = false
  cluster = {
    name         = "xstudio"
    version      = "16"
    versionCitus = "12.1"
    adminLogin = {
      userPassword = "P@ssword1234"
    }
    firewallRules = [
      {
        enable       = false
        startAddress = ""
        endAddress   = ""
      }
    ]
  }
  node = {
    serverEdition = "MemoryOptimized"
    storageMB     = 524288
    coreCount     = 2
    count         = 0
    configuration = {
    }
  }
  coordinator = {
    serverEdition = "GeneralPurpose"
    storageMB     = 131072
    coreCount     = 2
    configuration = {
    }
    shards = {
      enable = true
    }
  }
  roles = [
    {
      enable   = false
      name     = ""
      password = ""
    }
  ]
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

###################################################################################################
# Cosmos DB Apache Cassandra (https://learn.microsoft.com/azure/cosmos-db/cassandra/introduction) #
###################################################################################################

cosmosCassandra = {
  enable = false
  account = {
    name = "xstudio"
  }
  databases = [
    {
      enable     = false
      name       = "Media1"
      throughput = null
      tables = [
        {
          enable     = false
          name       = ""
          throughput = null
          schema = {
            partitionKeys = [
              {
                enable = false
                name   = ""
              }
            ]
            clusterKeys = [
              {
                enable  = false
                name    = ""
                orderBy = "" # Asc or Desc
              }
            ]
            columns = [
              {
                enable = false
                name   = ""
                type   = ""
              }
            ]
          }
        }
      ]
    }
  ]
}

########################################################################################################################
# Apache Cassandra Managed Instance (https://learn.microsoft.com/azure/managed-instance-apache-cassandra/introduction) #
########################################################################################################################

apacheCassandra = {
  enable = false
  cluster = {
    name    = "xstudio"
    version = "4.0"
    adminLogin = {
      userPassword = "P@ssword1234"
    }
  }
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

###############################################################################################
# Cosmos DB Apache Gremlin (https://learn.microsoft.com/azure/cosmos-db/gremlin/introduction) #
###############################################################################################

gremlin = {
  enable = false
  account = {
    name = "xstudio"
  }
  databases = [
    {
      enable     = false
      name       = "Media1"
      throughput = null
      graphs = [
        {
          enable     = false
          name       = ""
          throughput = null
          partitionKey = {
            path    = ""
            version = 2
          }
        }
      ]
    }
  ]
}

####################################################################################
# Cosmos DB Table (https://learn.microsoft.com/azure/cosmos-db/table/introduction) #
####################################################################################

table = {
  enable = false
  account = {
    name = "xstudio"
  }
  tables = [
    {
      enable     = false
      name       = ""
      throughput = null
    }
  ]
}

##############################################################################
# Event Hub  (https://learn.microsoft.com/azure/event-hubs/event-hubs-about) #
##############################################################################

eventHub = {
  enable = true
  name   = "xstudio"
  tier   = "Standard"
}

#################################################################
# Functions - https://learn.microsoft.com/azure/azure-functions #
#################################################################

functionApp = {
  name = "xstudio"
  servicePlan = {
    computeType = "Y1"
  }
  fileShare = {
    name   = "functions"
    sizeGB = 5
  }
  siteConfig = {
    alwaysOn = false
  }
}
