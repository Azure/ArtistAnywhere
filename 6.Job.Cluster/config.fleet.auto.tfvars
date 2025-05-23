##################################################################################
# Compute Fleet (https://learn.microsoft.com/azure/azure-compute-fleet/overview) #
##################################################################################

computeFleets = [
  {
    enable = false
    name   = "JobClusterXLCA"
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
        versionId         = "2.0.0"
        galleryName       = "hpcai"
        definitionName    = "Linux"
        resourceGroupName = "AAA.Image"
      }
      osDisk = {
        type        = "Linux"
        storageType = "Premium_LRS"
        cachingMode = "ReadOnly"
        sizeGB      = 0
        ephemeral = { # https://learn.microsoft.com/azure/virtual-machines/ephemeral-os-disks
          enable    = true
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
          name     = "Custom"
          fileName = "cse.sh"
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
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
      }
    }
  },
  {
    enable = false
    name   = "JobClusterXWCA"
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
        versionId         = "2.0.0"
        galleryName       = "hpcai"
        definitionName    = "WinCluster"
        resourceGroupName = "AAA.Image"
      }
      osDisk = {
        type        = "Windows"
        storageType = "Premium_LRS"
        cachingMode = "ReadOnly"
        sizeGB      = 0
        ephemeral = { # https://learn.microsoft.com/azure/virtual-machines/ephemeral-os-disks
          enable    = true
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
          name     = "Custom"
          fileName = "cse.ps1"
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
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
      }
    }
  }
]
