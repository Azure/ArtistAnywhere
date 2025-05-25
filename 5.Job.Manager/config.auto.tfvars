resourceGroupName = "AAA.Job.Manager"

#########################################################################
# Virtual Machines (https://learn.microsoft.com/azure/virtual-machines) #
#########################################################################

virtualMachines = [
  {
    enable = false
    name   = "JobManagerXL"
    size   = "Standard_D8as_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
    image = {
      versionId         = "1.0.0"
      galleryName       = "hpcai"
      definitionName    = "LnxX"
      resourceGroupName = "AAA.Image.Gallery"
    }
    osDisk = {
      type        = "Linux"
      storageType = "Premium_LRS"
      cachingMode = "ReadWrite"
      sizeGB      = 0
    }
    network = {
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
      }
    }
    extension = {
      custom = {
        enable   = true
        name     = "Custom"
        fileName = "cse.sh"
        parameters = {
          autoScale = {
            enable                   = false
            resourceGroupName        = "AAA.Job.Cluster"
            jobManagerName           = "Deadline"
            jobClusterName           = "JobClusterXLCA"
            jobClusterNodeLimit      = 100
            workerIdleDeleteSeconds  = 300
            jobWaitThresholdSeconds  = 60
            detectionIntervalSeconds = 60
          }
        }
      }
    }
    monitor = {
      enable = true
      metric = {
        category = "AllMetrics"
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
  },
  {
    enable = false
    name   = "JobManagerXW"
    size   = "Standard_D8as_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
    image = {
      versionId         = "1.0.0"
      galleryName       = "hpcai"
      definitionName    = "WinServer"
      resourceGroupName = "AAA.Image.Gallery"
    }
    osDisk = {
      type        = "Windows"
      storageType = "Premium_LRS"
      cachingMode = "ReadWrite"
      sizeGB      = 0
    }
    network = {
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
      }
    }
    extension = {
      custom = {
        enable   = true
        name     = "Custom"
        fileName = "cse.ps1"
        parameters = {
          autoScale = {
            enable                   = false
            resourceGroupName        = "AAA.Job.Cluster"
            jobManagerName           = "Deadline"
            jobClusterName           = "JobClusterXWCA"
            jobClusterNodeLimit      = 100
            workerIdleDeleteSeconds  = 300
            jobWaitThresholdSeconds  = 60
            detectionIntervalSeconds = 60
          }
        }
      }
    }
    monitor = {
      enable = true
      metric = {
        category = "AllMetrics"
      }
    }
    adminLogin = {
      userName     = ""
      userPassword = ""
      sshKeyPublic = ""
      passwordAuth = {
        disable = false
      }
    }
  }
]

############################################################################
# Private DNS (https://learn.microsoft.com/azure/dns/private-dns-overview) #
############################################################################

dnsRecord = {
  name       = "job"
  ttlSeconds = 300
}

########################
# Brownfield Resources #
########################

virtualNetwork = {
  name              = "HPC"
  subnetName        = "Cluster"
  edgeZoneName      = "" # "LosAngeles"
  resourceGroupName = "AAA.Network.SouthCentralUS" # "AAA.Network.WestUS.LosAngeles"
}

privateDNS = {
  zoneName          = "azure.hpc"
  resourceGroupName = "AAA.Network"
}

activeDirectory = {
  enable = false
  domain = {
    name = "azure.hpc"
  }
  machine = {
    name = "WinAD"
    adminLogin = {
      userName     = ""
      userPassword = ""
    }
  }
}
