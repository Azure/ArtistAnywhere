resourceGroupName = "ArtistAnywhere.Scheduler" # Alphanumeric, underscores, hyphens, periods and parenthesis are allowed

#########################################################################
# Virtual Machines (https://learn.microsoft.com/azure/virtual-machines) #
#########################################################################

virtualMachines = [
  {
    enable = false
    name   = "LnxScheduler"
    size   = "Standard_D8as_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
    image = {
      id = "/subscriptions/5cc0d8f1-3643-410c-8646-1a2961134bd3/resourceGroups/ArtistAnywhere.Image/providers/Microsoft.Compute/galleries/xstudio/images/Linux/versions/1.0.0"
      plan = {
        enable    = false
        publisher = ""
        product   = ""
        name      = ""
      }
    }
    adminLogin = {
      userName     = "xadmin"
      userPassword = "P@ssword1234"
      sshPublicKey = "" # "ssh-rsa ..."
      passwordAuth = {
        disable = false
      }
    }
    operatingSystem = {
      type = "Linux"
      disk = {
        storageType = "Premium_LRS"
        cachingType = "ReadWrite"
        sizeGB      = 0
      }
    }
    network = {
      subnetName = "Farm"
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
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
            enable                   = false
            fileName                 = "scale.sh"
            resourceGroupName        = "ArtistAnywhere.Farm.West"
            scaleSetName             = "LnxFarmC"
            scaleSetMachineCountMax  = 100
            jobWaitThresholdSeconds  = 300
            workerIdleDeleteSeconds  = 600
            detectionIntervalSeconds = 60
          }
        }
      }
      monitor = {
        enable = false
        name   = "Monitor"
      }
    }
  },
  {
    enable = false
    name   = "WinScheduler"
    size   = "Standard_D8as_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
    image = {
      id = "/subscriptions/5cc0d8f1-3643-410c-8646-1a2961134bd3/resourceGroups/ArtistAnywhere.Image/providers/Microsoft.Compute/galleries/xstudio/images/WinServer/versions/1.0.0"
      plan = {
        enable    = false
        publisher = ""
        product   = ""
        name      = ""
      }
    }
    adminLogin = {
      userName     = "xadmin"
      userPassword = "P@ssword1234"
      sshPublicKey = "" # "ssh-rsa ..."
      passwordAuth = {
        disable = false
      }
    }
    operatingSystem = {
      type = "Windows"
      disk = {
        storageType = "Premium_LRS"
        cachingType = "ReadWrite"
        sizeGB      = 0
      }
    }
    network = {
      subnetName = "Farm"
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
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
            enable                   = false
            fileName                 = "scale.ps1"
            resourceGroupName        = "ArtistAnywhere.Farm.West"
            scaleSetName             = "WinFarmC"
            scaleSetMachineCountMax  = 100
            jobWaitThresholdSeconds  = 300
            workerIdleDeleteSeconds  = 600
            detectionIntervalSeconds = 60
          }
        }
      }
      monitor = {
        enable = false
        name   = "Monitor"
      }
    }
  }
]

############################################################################
# Private DNS (https://learn.microsoft.com/azure/dns/private-dns-overview) #
############################################################################

dnsRecord = {
  name        = "scheduler"
  ttlSeconds  = 300
}

###############################################################################################################
# Active Directory (https://learn.microsoft.comtroubleshoot/windows-server/identity/active-directory-overview #
###############################################################################################################

activeDirectory = {
  enable     = true
  domainName = "artist.studio"
}

#######################################################################
# Resource dependency configuration for pre-existing deployments only #
#######################################################################

existingNetwork = {
  enable             = false
  name               = ""
  subnetName         = ""
  resourceGroupName  = ""
  privateDnsZoneName = ""
}
