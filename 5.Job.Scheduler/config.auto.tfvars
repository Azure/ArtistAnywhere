resourceGroupName = "ArtistAnywhere.JobScheduler" # Alphanumeric, underscores, hyphens, periods and parenthesis are allowed

#########################################################################
# Virtual Machines (https://learn.microsoft.com/azure/virtual-machines) #
#########################################################################

virtualMachines = [
  {
    enable = false
    name   = "LnxJobScheduler"
    size   = "Standard_D8as_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
    image = {
      resourceGroupName = "ArtistAnywhere.Image"
      galleryName       = "xstudio"
      definitionName    = "Linux"
      versionId         = "1.0.0"
      plan = {
        publisher = ""
        product   = ""
        name      = ""
      }
    }
    osDisk = {
      type        = "Linux"
      storageType = "Premium_LRS"
      cachingType = "ReadWrite"
      sizeGB      = 0
    }
    network = {
      subnetName = "Farm"
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
      }
      locationExtended = {
        enable = false
      }
      staticIpAddress = ""
    }
    extension = {
      custom = {
        enable   = true
        name     = "Initialize"
        fileName = "initialize.sh"
        parameters = {
          autoScale = {
            enable                   = true
            resourceGroupName        = "ArtistAnywhere.Farm"
            jobSchedulerName         = "Deadline"
            computeFarmName          = "LnxFarmC"
            computeFarmNodeCountMax  = 100
            workerIdleDeleteSeconds  = 300
            jobWaitThresholdSeconds  = 60
            detectionIntervalSeconds = 60
          }
        }
      }
      monitor = {
        enable = false
        name   = "Monitor"
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
    name   = "WinJobScheduler"
    size   = "Standard_D8as_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
    image = {
      resourceGroupName = "ArtistAnywhere.Image"
      galleryName       = "xstudio"
      definitionName    = "WinServer"
      versionId         = "1.0.0"
      plan = {
        publisher = ""
        product   = ""
        name      = ""
      }
    }
    osDisk = {
      type        = "Windows"
      storageType = "Premium_LRS"
      cachingType = "ReadWrite"
      sizeGB      = 0
    }
    network = {
      subnetName = "Farm"
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
      }
      locationExtended = {
        enable = false
      }
      staticIpAddress = "10.0.127.0"
    }
    extension = {
      custom = {
        enable   = true
        name     = "Initialize"
        fileName = "initialize.ps1"
        parameters = {
          autoScale = {
            enable                   = true
            resourceGroupName        = "ArtistAnywhere.Farm"
            jobSchedulerName         = "Deadline"
            computeFarmName          = "WinFarmC"
            computeFarmNodeCountMax  = 100
            workerIdleDeleteSeconds  = 300
            jobWaitThresholdSeconds  = 60
            detectionIntervalSeconds = 60
          }
        }
      }
      monitor = {
        enable = false
        name   = "Monitor"
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

######################################################################
# CycleCloud (https://learn.microsoft.com/azure/cyclecloud/overview) #
######################################################################

cycleCloud = {
  enable = false
  machine = {
    name = "xstudio"
    size = "Standard_D8as_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
    image = {
      publisher = "AzureCycleCloud"
      product   = "Azure-CycleCloud"
      name      = "CycleCloud8-Gen2"
      version   = "8.6.520241024"
    }
    osDisk = {
      storageType = "Premium_LRS"
      cachingType = "ReadWrite"
      sizeGB      = 0
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
    subnetName = "Farm"
    acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
      enable = true
    }
    locationExtended = {
      enable = false
    }
  }
}

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

existingNetwork = {
  enable            = false
  name              = ""
  subnetName        = ""
  resourceGroupName = ""
  privateDns = {
    zoneName          = ""
    resourceGroupName = ""
  }
}
