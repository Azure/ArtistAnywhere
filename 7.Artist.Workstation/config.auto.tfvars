resourceGroupName = "ArtistAnywhere.Workstation" # Alphanumeric, underscores, hyphens, periods and parenthesis are allowed

#########################################################################
# Virtual Machines (https://learn.microsoft.com/azure/virtual-machines) #
#########################################################################

virtualMachines = [
  {
    enable = false
    name   = "LnxArtistN"
    size   = "Standard_NV36ads_A10_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
    count  = 1
    image = {
      id = "/subscriptions/5cc0d8f1-3643-410c-8646-1a2961134bd3/resourceGroups/ArtistAnywhere.Image/providers/Microsoft.Compute/galleries/xstudio/images/Linux/versions/3.0.0"
      plan = {
        enable    = false
        publisher = ""
        product   = ""
        name      = ""
      }
    }
    network = {
      subnetName = "Workstation"
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
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
    adminLogin = {
      userName     = ""
      userPassword = ""
      sshPublicKey = "" # "ssh-rsa ..."
      passwordAuth = {
        disable = false
      }
    }
    extension = {
      initialize = {
        enable   = true
        fileName = "initialize.sh"
        parameters = {
          pcoipLicenseKey = ""
        }
      }
      monitor = {
        enable = false
      }
    }
  },
  {
    enable = false
    name   = "LnxArtistA"
    size   = "Standard_NG32ads_V620_v1" # https://learn.microsoft.com/azure/virtual-machines/sizes
    count  = 1
    image = {
      id = "/subscriptions/5cc0d8f1-3643-410c-8646-1a2961134bd3/resourceGroups/ArtistAnywhere.Image/providers/Microsoft.Compute/galleries/xstudio/images/Linux/versions/3.1.0"
      plan = {
        enable    = false
        publisher = ""
        product   = ""
        name      = ""
      }
    }
    network = {
      subnetName = "Workstation"
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
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
    adminLogin = {
      userName     = ""
      userPassword = ""
      sshPublicKey = "" # "ssh-rsa ..."
      passwordAuth = {
        disable = false
      }
    }
    extension = {
      initialize = {
        enable   = true
        fileName = "initialize.sh"
        parameters = {
          pcoipLicenseKey = ""
        }
      }
      monitor = {
        enable = false
      }
    }
  },
  {
    enable = false
    name   = "WinArtistN"
    size   = "Standard_NV36ads_A10_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
    count  = 1
    image = {
      id = "/subscriptions/5cc0d8f1-3643-410c-8646-1a2961134bd3/resourceGroups/ArtistAnywhere.Image/providers/Microsoft.Compute/galleries/xstudio/images/WinArtist/versions/3.0.0"
      plan = {
        enable    = false
        publisher = ""
        product   = ""
        name      = ""
      }
    }
    network = {
      subnetName = "Workstation"
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
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
    adminLogin = {
      userName     = ""
      userPassword = ""
      sshPublicKey = "" # "ssh-rsa ..."
      passwordAuth = {
        disable = false
      }
    }
    extension = {
      initialize = {
        enable   = true
        fileName = "initialize.ps1"
        parameters = {
          pcoipLicenseKey = ""
        }
      }
      monitor = {
        enable = false
      }
    }
  },
  {
    enable = false
    name   = "WinArtistA"
    size   = "Standard_NG32ads_V620_v1" # https://learn.microsoft.com/azure/virtual-machines/sizes
    count  = 1
    image = {
      id = "/subscriptions/5cc0d8f1-3643-410c-8646-1a2961134bd3/resourceGroups/ArtistAnywhere.Image/providers/Microsoft.Compute/galleries/xstudio/images/WinArtist/versions/3.1.0"
      plan = {
        enable    = false
        publisher = ""
        product   = ""
        name      = ""
      }
    }
    network = {
      subnetName = "Workstation"
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
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
    adminLogin = {
      userName     = ""
      userPassword = ""
      sshPublicKey = "" # "ssh-rsa ..."
      passwordAuth = {
        disable = false
      }
    }
    extension = {
      initialize = {
        enable   = true
        fileName = "initialize.ps1"
        parameters = {
          pcoipLicenseKey = ""
        }
      }
      monitor = {
        enable = false
      }
    }
  }
]

#######################################################################
# Resource dependency configuration for pre-existing deployments only #
#######################################################################

activeDirectory = {
  enable           = false
  domainName       = "artist.studio"
  domainServerName = "WinScheduler"
  orgUnitPath      = ""
  adminUsername    = ""
  adminPassword    = ""
}

existingNetwork = {
  enable            = false
  name              = ""
  subnetName        = ""
  resourceGroupName = ""
}
