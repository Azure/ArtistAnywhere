resourceGroupName = "ArtistAnywhere.Cluster.JobScheduler.SQL" # Alphanumeric, underscores, hyphens, periods and parenthesis are allowed

############################################################################################
# MySQL Flexible Server (https://learn.microsoft.com/azure/mysql/flexible-server/overview) #
############################################################################################

mySQL = {
  enable  = false
  name    = "xstudio"
  type    = "B_Standard_B1ms" # https://learn.microsoft.com/azure/mysql/flexible-server/concepts-service-tiers-storage
  version = "8.0.21"
  delegatedSubnet = {
    enable = true
  }
  authentication = {
    activeDirectory = {
      enable = false
    }
  }
  storage = {
    sizeGB = 20
    iops   = 0
    autoGrow = {
      enabled = true
    }
    ioScaling = {
      enabled = true
    }
  }
  backup = {
    retentionDays = 7
    geoRedundant = {
      enable = false
    }
    vault = {
      enable     = false
      name       = "Default"
      type       = "VaultStore"
      redundancy = "LocallyRedundant"
      softDelete = "On"
      retention = {
        days = 14
      }
      crossRegion = {
        enable = false
      }
    }
  }
  highAvailability = {
    enable = false
    mode   = "SameZone"
  }
  maintenanceWindow = {
    enable    = false
    dayOfWeek = 0
    start = {
      hour   = 0
      minute = 0
    }
  }
  adminLogin = {
    userName     = ""
    userPassword = ""
  }
  encryption = {
    enable = false
  }
  database = {
    enable    = false
    name      = "ccws"
    charset   = "utf8"
    collation = "utf8_general_ci"
  }
}

##############################################################################################################
# PostgreSQL Flexible Server (https://learn.microsoft.com/azure/postgresql/flexible-server/service-overview) #
##############################################################################################################

postgreSQL = {
  enable  = false
  name    = "xstudio"
  type    = "B_Standard_B1ms" # https://learn.microsoft.com/azure/postgresql/flexible-server/concepts-compute
  version = "16"
  delegatedSubnet = {
    enable = true
  }
  authentication = {
    password = {
      enable = true
    }
    activeDirectory = {
      enable = false
    }
  }
  storage = {
    type   = "P4"
    sizeMB = 32768
    autoGrow = {
      enabled = true
    }
  }
  backup = {
    retentionDays = 7
    geoRedundant = {
      enable = false
    }
    vault = {
      enable     = false
      name       = "Default"
      type       = "VaultStore"
      redundancy = "LocallyRedundant"
      softDelete = "On"
      retention = {
        days = 14
      }
      crossRegion = {
        enable = false
      }
    }
  }
  highAvailability = {
    enable = false
    mode   = "SameZone"
  }
  maintenanceWindow = {
    enable    = false
    dayOfWeek = 0
    start = {
      hour   = 0
      minute = 0
    }
  }
  adminLogin = {
    userName     = ""
    userPassword = ""
  }
  encryption = {
    enable = false
  }
  database = {
    enable    = false
    name      = "opencue"
    charset   = "UTF8"
    collation = "English_United States.1252"
  }
}

########################
# Brownfield Resources #
########################

existingNetwork = {
  enable            = false
  name              = ""
  subnetName        = ""
  resourceGroupName = ""
}
