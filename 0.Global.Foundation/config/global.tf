variable subscriptionId {
  default = "" # Set to your Azure subscription id
}

variable resourceLocation {
  default = {
    regionName = "SouthCentralUS" # Set from "az account list-locations --query [].name"
    extendedZone = {
      enable     = false
      name       = "LosAngeles"
      regionName = "WestUS"
    }
  }
}

variable resourceGroupName {
  default = "ArtistAnywhere" # Alphanumeric, underscores, hyphens, periods and parenthesis are allowed
}

#############################################################################################################
# Managed Identity (https://learn.microsoft.com/entra/identity/managed-identities-azure-resources/overview) #
#############################################################################################################

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

##############################################################################
# Event Grid (https://learn.microsoft.com/azure/event-grid/overview)         #
# Event Hub  (https://learn.microsoft.com/azure/event-hubs/event-hubs-about) #
##############################################################################

variable message {
  default = {
    eventGrid = {
      name     = "xstudio"
      type     = "Standard"
      capacity = 1
    }
    eventHub = {
      name = "xstudio"
      type = "Standard"
    }
  }
}

######################################################################
# Monitor (https://learn.microsoft.com/azure/azure-monitor/overview) #
######################################################################

variable monitor {
  default = {
    name = "xstudio"
  }
}

###################################################################################################
# Defender (https://learn.microsoft.com/azure/defender-for-cloud/defender-for-cloud-introduction) #
###################################################################################################

variable defender {
  default = {
    storage = {
      malwareScanning = {
        enable        = true
        maxPerMonthGB = 5000
      }
      sensitiveDataDiscovery = {
        enable = true
      }
    }
  }
}

output subscriptionId {
  value = var.subscriptionId
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

output message {
  value = var.message
}

output monitor {
  value = var.monitor
}

output defender {
  value = var.defender
}

output linux {
  value = {
    publisher = "AlmaLinux"
    offer     = "AlmaLinux-x86_64"
    sku       = "9-Gen2"
    version   = "9.4.2024080501"
  }
}

output version {
  value = {
    nvidia_cuda              = "12.6.3"
    nvidia_optix             = "8.0.0"
    az_blob_nfs_mount        = "2.0.11"
    hp_anyware_agent         = "24.10.1"
    job_scheduler_deadline   = "10.4.0.13"
    job_scheduler_slurm      = "24.11.1"
    job_processor_pbrt       = "v4"
    job_processor_blender    = "4.3.2"
    script_extension_linux   = "2.1"
    script_extension_windows = "1.10"
    monitor_agent_linux      = "1.33"
    monitor_agent_windows    = "1.31"
  }
}
