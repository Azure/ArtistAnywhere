variable resourceLocation {
  default = {
    regionName = "EastUS" # Set from "az account list-locations --query [].name"
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

############################################################################
# Key Vault (https://learn.microsoft.com/azure/key-vault/general/overview) #
############################################################################

variable keyVault {
  default = {
    name = "xstudio" # Set to a globally unique name (alphanumeric, hyphens)
    secretName = {
      sshKeyPublic      = "SSHKeyPublic"
      sshKeyPrivate     = "SSHKeyPrivate"
      adminUsername     = "AdminUsername"
      adminPassword     = "AdminPassword"
      serviceUsername   = "ServiceUsername"
      servicePassword   = "ServicePassword"
      gatewayConnection = "GatewayConnection"
    }
    keyName = {
      dataEncryption = "DataEncryption"
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
    name = "xstudio"
  }
}

##########################################################################################
# App Configuration (https://learn.microsoft.com/azure/azure-app-configuration/overview) #
##########################################################################################

variable appConfig {
  default = {
    name = "xstudio"
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
      linux   = "1.32"
      windows = "1.29"
    }
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

output keyVault {
  value = var.keyVault
}

output eventGrid {
  value = var.eventGrid
}

output appConfig {
  value = var.appConfig
}

output monitor {
  value = var.monitor
}
