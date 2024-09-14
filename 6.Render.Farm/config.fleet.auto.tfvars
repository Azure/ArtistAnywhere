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
          name = "Standard_HB120rs_v3"
        },
        {
          name = "Standard_HB120-96rs_v3"
        },
        {
          name = "Standard_HB120-64rs_v3"
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
          name = "Standard_HB120rs_v3"
        },
        {
          name = "Standard_HB120-96rs_v3"
        },
        {
          name = "Standard_HB120-64rs_v3"
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
