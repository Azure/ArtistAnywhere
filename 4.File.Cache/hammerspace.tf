#######################################################################################################
# Hammerspace (https://azuremarketplace.microsoft.com/marketplace/apps/hammerspace.hammerspace_4_6_5) #
#######################################################################################################

variable hammerspace {
  type = object({
    namePrefix = string
    domainName = string
    metadata = object({
      machine = object({
        namePrefix = string
        size       = string
        count      = number
      })
      adminLogin = object({
        userName     = string
        userPassword = string
        sshPublicKey = string
        passwordAuth = object({
          disable = bool
        })
      })
      network = object({
        acceleration = object({
          enable = bool
        })
      })
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
    })
    data = object({
      machine = object({
        namePrefix = string
        size       = string
        count      = number
      })
      adminLogin = object({
        userName     = string
        userPassword = string
        sshPublicKey = string
        passwordAuth = object({
          disable = bool
        })
      })
      network = object({
        acceleration = object({
          enable = bool
        })
      })
      osDisk = object({
        storageType = string
        cachingType = string
        sizeGB      = number
      })
      dataDisk = object({
        storageType = string
        cachingType = string
        enableRaid0 = bool
        sizeGB      = number
        count       = number
      })
    })
  })
}
