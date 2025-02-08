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
      versionId         = "1.0.0"
      galleryName       = "xstudio"
      definitionName    = "Linux"
      resourceGroupName = "ArtistAnywhere.Image"
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
        name     = "Custom"
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
      versionId         = "1.0.0"
      galleryName       = "xstudio"
      definitionName    = "WinServer"
      resourceGroupName = "ArtistAnywhere.Image"
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
        name     = "Custom"
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
