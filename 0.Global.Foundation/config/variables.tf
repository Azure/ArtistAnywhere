variable resourceLocation {
  default = {
    regionName = "WestUS2" # Set from "az account list-locations --query [].name"
    nameSuffix = "West"
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
      linux   = "1.30"
      windows = "1.24"
    }
  }
}

#################################################################################
# Search (https://learn.microsoft.com/azure/search/search-what-is-azure-search) #
#################################################################################

variable search {
  default = {
    enable = false
    name   = "xstudio" # Set to a globally unique name (lowercase alphanumeric)
  }
}

############################################################################
# Key Vault (https://learn.microsoft.com/azure/key-vault/general/overview) #
############################################################################

variable keyVault {
  default = {
    enable = false
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

##########################################################################################
# App Configuration (https://learn.microsoft.com/azure/azure-app-configuration/overview) #
##########################################################################################

variable appConfig {
  default = {
    enable = false
    name   = "xstudio" # Set to a globally unique name (alphanumeric, hyphens)
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
  value = var.monitor
}

output search {
  value = var.search
}

output keyVault {
  value = var.keyVault
}

output appConfig {
  value = var.appConfig
}
