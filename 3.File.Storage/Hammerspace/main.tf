###################################################
# Hammerspace (https://www.hammerspace.com/azure) #
###################################################

variable resourceGroup {
  type = object({
    name     = string
    location = string
  })
}

variable virtualNetwork {
  type = object({
    name              = string
    subnetName        = string
    resourceGroupName = string
  })
}

variable privateDns {
  type = object({
    zoneName          = string
    resourceGroupName = string
    aRecord = object({
      name       = string
      ttlSeconds = number
    })
  })
}

variable adminLogin {
  type = object({
    userName     = string
    userPassword = string
    sshKeyPublic = string
  })
}

variable activeDirectory {
  type = object({
    enable       = bool
    domainName   = string
    servers      = string
    userName     = string
    userPassword = string
  })
}

variable hammerspace {
  type = object({
    version    = string
    namePrefix = string
    domainName = string
    metadata = object({
      machine = object({
        namePrefix = string
        size       = string
        count      = number
        osDisk = object({
          storageType = string
          cachingType = string
          sizeGB      = number
        })
        dataDisk = object({
          storageType = string
          cachingType = string
          sizeGB      = number
        })
        adminLogin = object({
          userName     = string
          userPassword = string
          sshKeyPublic = string
          passwordAuth = object({
            disable = bool
          })
        })
      })
      network = object({
        acceleration = object({
          enable = bool
        })
      })
    })
    data = object({
      machine = object({
        namePrefix = string
        size       = string
        count      = number
        osDisk = object({
          storageType = string
          cachingType = string
          sizeGB      = number
        })
        dataDisk = object({
          storageType = string
          cachingType = string
          sizeGB      = number
          count       = number
          raid0 = object({
            enable = bool
          })
        })
        adminLogin = object({
          userName     = string
          userPassword = string
          sshKeyPublic = string
          passwordAuth = object({
            disable = bool
          })
        })
      })
      network = object({
        acceleration = object({
          enable = bool
        })
      })
    })
    proximityPlacementGroup = object({
      enable = bool
    })
    storageAccounts = list(object({
      enable    = bool
      name      = string
      accessKey = string
    }))
    shares = list(object({
      enable = bool
      name   = string
      path   = string
      size   = number
      export = string
    }))
    volumes = list(object({
      enable = bool
      name   = string
      type   = string
      path   = string
      node = object({
        name    = string
        type    = string
        address = string
      })
      assimilation = object({
        enable = bool
        share = object({
          name = string
          path = object({
            source      = string
            destination = string
          })
        })
      })
    }))
    volumeGroups = list(object({
      enable      = bool
      name        = string
      volumeNames = list(string)
    }))
  })
}

data azurerm_subnet storage {
  name                 = var.virtualNetwork.subnetName
  resource_group_name  = var.virtualNetwork.resourceGroupName
  virtual_network_name = var.virtualNetwork.name
}

data azurerm_resource_group hammerspace {
  name = var.resourceGroup.name
}

locals {
  hsImage = {
    publisher = "Hammerspace"
    product   = "Hammerspace_BYOL_5_0"
    name      = "Hammerspace_5_0"
    version   = var.hammerspace.version
  }
  hsSubnetSize = "/${reverse(split("/", data.azurerm_subnet.storage.address_prefixes[0]))[0]}"
}

##############################################################################################
# Proximity Placement Group (https://learn.microsoft.com/azure/virtual-machines/co-location) #
##############################################################################################

resource azurerm_proximity_placement_group hammerspace {
  count               = var.hammerspace.proximityPlacementGroup.enable ? 1 : 0
  name                = var.hammerspace.namePrefix
  resource_group_name = var.resourceGroup.name
  location            = var.resourceGroup.location
}
