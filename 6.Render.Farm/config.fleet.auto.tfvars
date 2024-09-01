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
          name = "Standard_HB176rs_v4"
        },
        {
          name = "Standard_HB176-144rs_v4"
        },
        {
          name = "Standard_HB176-96rs_v4"
        }
      ]
      priority = {
        standard = {
          allocationStrategy = "LowestPrice"
          capacityTarget     = 0
          capacityMinimum    = 0
        }
        spot = {
          allocationStrategy = "PriceCapacityOptimized"
          evictionPolicy     = "Delete"
          capacityTarget     = 2
          capacityMinimum    = 2
          capacityMaintain = {
            enable = true
          }
        }
      }
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
    adminLogin = {
      userName     = ""
      userPassword = ""
      sshKeyPublic = ""
    }
  },
  {
    enable = false
    name   = "WinFarmC"
    machine = {
      namePrefix = ""
      sizes = [
        {
          name = "Standard_HB176rs_v4"
        },
        {
          name = "Standard_HB176-144rs_v4"
        },
        {
          name = "Standard_HB176-96rs_v4"
        }
      ]
      priority = {
        standard = {
          allocationStrategy = "LowestPrice"
          capacityTarget     = 0
          capacityMinimum    = 0
        }
        spot = {
          allocationStrategy = "PriceCapacityOptimized"
          evictionPolicy     = "Delete"
          capacityTarget     = 2
          capacityMinimum    = 2
          capacityMaintain = {
            enable = true
          }
        }
      }
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
    adminLogin = {
      userName     = ""
      userPassword = ""
      sshKeyPublic = ""
    }
  }
]
