variable resourceLocation {
  default = {
    name = "SouthCentralUS" # Set from "az account list-locations --query [].name"
    extendedZone = {
      enable   = false
      name     = "LosAngeles"
      location = "WestUS"
    }
  }
}

#############################################################################################################
# Managed Identity (https://learn.microsoft.com/entra/identity/managed-identities-azure-resources/overview) #
#############################################################################################################

variable managedIdentity {
  default = {
    name = "xstudio" # Alphanumeric, underscores and hyphens are allowed
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

output resourceLocation {
  value = var.resourceLocation
}

output managedIdentity {
  value = var.managedIdentity
}

output keyVault {
  value = var.keyVault
}

output monitor {
  value = var.monitor
}

output defender {
  value = var.defender
}

output blobStorage {
  value = {
    apiVersion   = "2025-05-05"
    endpointUrl  = "https://xstudio.blob.core.windows.net/bin"
    authTokenUrl = "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2021-02-01&resource=https%3A%2F%2Fstorage.azure.com%2F"
  }
}

output image {
  value = {
    linux = {
      enable    = true
      publisher = "AlmaLinux"
      offer     = "AlmaLinux-x86_64"
      sku       = "9-Gen2"
      version   = "9.5.202411260"
    }
    windows = {
      enable  = true
      version = "Latest"
    }
  }
}

output version {
  value = {
    monitor_agent_linux      = "1.33"
    monitor_agent_windows    = "1.32"
    job_scheduler_slurm      = "24.11.3"
    job_scheduler_deadline   = "10.4.0.13"
    job_processor_pbrt       = "v4"
    job_processor_blender    = "4.4.0"
    script_extension_linux   = "2.1"
    script_extension_windows = "1.10"
    nvidia_cuda_windows      = "12.8.1"
    hp_anyware_agent         = "24.10.2"
  }
}

output hammerspace {
  value = {
    enable     = false
    version    = "24.06.19"
    namePrefix = "xstudio"
    domainName = "azure.studio"
    metadata = { # Anvil
      machine = {
        namePrefix = "-anvil"
        size       = "Standard_E8as_v5"
        count      = 1
        osDisk = {
          storageType = "Premium_LRS"
          cachingMode = "ReadWrite"
          sizeGB      = 128
        }
        dataDisk = {
          storageType = "Premium_LRS"
          cachingMode = "None"
          sizeGB      = 1024
        }
        adminLogin = {
          userName     = ""
          userPassword = ""
          sshKeyPublic = ""
          passwordAuth = {
            disable = true
          }
        }
      }
      network = {
        acceleration = {
          enable = true
        }
      }
    }
    data = { # DSX
      machine = {
        namePrefix = "-dsx"
        size       = "Standard_E32as_v5"
        count      = 2
        osDisk = {
          storageType = "Premium_LRS"
          cachingMode = "ReadWrite"
          sizeGB      = 128
        }
        dataDisk = {
          storageType = "Premium_LRS"
          cachingMode = "None"
          sizeGB      = 1024
          count       = 4
          raid0 = {
            enable = false
          }
        }
        adminLogin = {
          userName     = ""
          userPassword = ""
          sshKeyPublic = ""
          passwordAuth = {
            disable = true
          }
        }
      }
      network = {
        acceleration = {
          enable = true
        }
      }
    }
    proximityPlacementGroup = {
      enable = false
    }
    storageAccounts = [
      {
        enable    = false
        name      = ""
        accessKey = ""
      }
    ]
    shares = [
      {
        enable = false
        name   = ""
        path   = ""
        size   = 0
        export = "*,rw,no-root-squash"
      }
    ]
    volumes = [
      {
        enable = false
        name   = ""
        type   = "READ_WRITE"
        path   = ""
        node = {
          name    = ""
          type    = ""
          address = ""
        }
        assimilation = {
          enable = false
          share = {
            name = ""
            path = {
              source      = ""
              destination = ""
            }
          }
        }
      }
    ]
    volumeGroups = [
      {
        enable = false
        name   = ""
        volumeNames = [
        ]
      }
    ]
  }
}
