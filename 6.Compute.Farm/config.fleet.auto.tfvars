##################################################################################
# Compute Fleet (https://learn.microsoft.com/azure/azure-compute-fleet/overview) #
##################################################################################

computeFleets = [
  {
    enable = false
    name   = "LnxFarmC"
    machine = {
      namePrefix = ""
      sizes = [
        {
          name = "Standard_HX176rs"
        },
        {
          name = "Standard_HX176-144rs"
        },
        {
          name = "Standard_HX176-96rs"
        }
      ]
      image = {
        resourceGroupName = "ArtistAnywhere.Image"
        galleryName       = "xstudio"
        definitionName    = "Linux"
        versionId         = "2.0.0"
        plan = {
          publisher = ""
          product   = ""
          name      = ""
        }
      }
      osDisk = {
        type        = "Linux"
        storageType = "Premium_LRS"
        cachingType = "ReadOnly"
        sizeGB      = 0
        ephemeral = { # https://learn.microsoft.com/azure/virtual-machines/ephemeral-os-disks
          enable    = false
          placement = "ResourceDisk"
        }
      }
      priority = {
        standard = {
          allocationStrategy = "LowestPrice"
          capacityTarget     = 2
          capacityMinimum    = 1
        }
        spot = {
          allocationStrategy = "PriceCapacityOptimized"
          evictionPolicy     = "Delete"
          capacityTarget     = 0
          capacityMinimum    = 0
          capacityMaintain = {
            enable = true
          }
        }
      }
      extension = {
        custom = {
          enable   = true
          name     = "Initialize"
          fileName = "initialize.sh"
          parameters = {
            terminateNotification = { # https://learn.microsoft.com/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-terminate-notification
              enable       = false
              delayTimeout = "PT5M"
            }
          }
        }
        health = {
          enable      = true
          name        = "Health"
          protocol    = "tcp"
          port        = 111
          requestPath = ""
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
  },
  {
    enable = false
    name   = "WinFarmC"
    machine = {
      namePrefix = ""
      sizes = [
        {
          name = "Standard_HX176rs"
        },
        {
          name = "Standard_HX176-144rs"
        },
        {
          name = "Standard_HX176-96rs"
        }
      ]
      image = {
        resourceGroupName = "ArtistAnywhere.Image"
        galleryName       = "xstudio"
        definitionName    = "WinFarm"
        versionId         = "2.0.0"
        plan = {
          publisher = ""
          product   = ""
          name      = ""
        }
      }
      osDisk = {
        type        = "Windows"
        storageType = "Premium_LRS"
        cachingType = "ReadOnly"
        sizeGB      = 0
        ephemeral = { # https://learn.microsoft.com/azure/virtual-machines/ephemeral-os-disks
          enable    = false
          placement = "ResourceDisk"
        }
      }
      priority = {
        standard = {
          allocationStrategy = "LowestPrice"
          capacityTarget     = 2
          capacityMinimum    = 1
        }
        spot = {
          allocationStrategy = "PriceCapacityOptimized"
          evictionPolicy     = "Delete"
          capacityTarget     = 0
          capacityMinimum    = 0
          capacityMaintain = {
            enable = true
          }
        }
      }
      extension = {
        custom = {
          enable   = true
          name     = "Initialize"
          fileName = "initialize.ps1"
          parameters = {
            terminateNotification = { # https://learn.microsoft.com/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-terminate-notification
              enable       = false
              delayTimeout = "PT5M"
            }
          }
        }
        health = {
          enable      = true
          name        = "Health"
          protocol    = "tcp"
          port        = 445
          requestPath = ""
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
]
