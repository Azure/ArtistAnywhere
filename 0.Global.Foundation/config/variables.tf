variable resourceLocation {
  default = {
    regionName = "WestUS2" # Set from "az account list-locations --query [].name"
    edgeZone = {
      enable     = false
      name       = "LosAngeles"
      regionName = "WestUS"
    }
  }
}

variable resourceGroupName {
  default = "ArtistAnywhere" # Alphanumeric, underscores, hyphens, periods and parenthesis are allowed
}

#####################################################################################################################
# Managed Identity (https://learn.microsoft.com/azure/active-directory/managed-identities-azure-resources/overview) #
#####################################################################################################################

variable managedIdentity {
  default = {
    name = "xstudio" # Alphanumeric, underscores and hyphens are allowed
  }
}

###################################################################################
# Storage (https://learn.microsoft.com/azure/storage/common/storage-introduction) #
###################################################################################

variable storage {
  default = {
    accountName = "xstudio0" # Set to a globally unique name (lowercase alphanumeric)
    containerName = {
      terraformState = "terraform-state"
      videoIndexer   = "video-indexer"
    }
  }
}

######################################################################
# Monitor (https://learn.microsoft.com/azure/azure-monitor/overview) #
######################################################################

variable monitor {
  default = {
    enable = true
    name   = "xstudio"
    agentVersion = {
      linux   = "1.31"
      windows = "1.26"
    }
  }
}

############################################################################
# Key Vault (https://learn.microsoft.com/azure/key-vault/general/overview) #
############################################################################

variable keyVault {
  default = {
    enable = true
    name   = "xstudio" # Set to a globally unique name (alphanumeric, hyphens)
    secretName = {
      adminUsername     = "AdminUsername"
      adminPassword     = "AdminPassword"
      databaseUsername  = "DatabaseUsername"
      databasePassword  = "DatabasePassword"
      gatewayConnection = "GatewayConnection"
    }
    keyName = {
      dataEncryption  = "DataEncryption"
      cacheEncryption = "CacheEncryption"
    }
    certificateName = {
    }
  }
}

######################################################################
# Event Grid (https://learn.microsoft.com/azure/event-grid/overview) #
######################################################################

variable eventGrid {
  default = {
    enable = false
    name   = "xstudio"
  }
}

##########################################################################################
# App Configuration (https://learn.microsoft.com/azure/azure-app-configuration/overview) #
##########################################################################################

variable appConfig {
  default = {
    enable = false
    name   = "xstudio"
  }
}

################################################################################################
# Traffic Manager (https://learn.microsoft.com/azure/traffic-manager/traffic-manager-overview) #
################################################################################################

variable trafficManager {
  default = {
    enable = false
    name   = "xstudio"
  }
}

output resourceLocation {
  value = var.resourceLocation
}

output resourceGroupName {
  value = var.resourceGroupName
}

output managedIdentity {
  value = var.managedIdentity
}

output storage {
  value = var.storage
}

output monitor {
  value = terraform.workspace != "shared" ? var.monitor : merge(var.monitor, {
    enable = false
  })
}

output keyVault {
  value = terraform.workspace != "shared" ? var.keyVault : merge(var.keyVault, {
    enable = false
  })
}

output eventGrid {
  value = terraform.workspace != "shared" ? var.eventGrid : merge(var.eventGrid, {
    enable = false
  })
}

output appConfig {
  value = terraform.workspace != "shared" ? var.appConfig : merge(var.appConfig, {
    enable = false
  })
}

output trafficManager {
  value = terraform.workspace != "shared" ? var.trafficManager : merge(var.trafficManager, {
    enable = false
  })
}
