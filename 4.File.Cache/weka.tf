#######################################################################################################
# Weka (https://azuremarketplace.microsoft.com/marketplace/apps/weka1652213882079.weka_data_platform) #
#######################################################################################################

variable weka {
  type = object({
    enable   = bool
    version  = string
    apiToken = string
    name = object({
      resource = string
      display  = string
    })
    machine = object({
      size  = string
      count = number
      image = object({
        resourceGroupName = string
        galleryName       = string
        definitionName    = string
        versionId         = string
        plan = object({
          publisher = string
          product   = string
          name      = string
        })
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
    network = object({
      acceleration = object({
        enable = bool
      })
      dnsRecord = object({
        name       = string
        ttlSeconds = number
      })
    })
    terminateNotification = object({
      enable       = bool
      delayTimeout = string
    })
    objectTier = object({
      percent = number
      storage = object({
        accountName   = string
        accountKey    = string
        containerName = string
      })
    })
    fileSystem = object({
      name         = string
      groupName    = string
      autoScale    = bool
      authRequired = bool
      loadFiles    = bool
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
    dataProtection = object({
      stripeWidth = number
      parityLevel = number
      hotSpare    = number
    })
    healthExtension = object({
      protocol    = string
      port        = number
      requestPath = string
    })
    license = object({
      key = string
      payGo = object({
        planId    = string
        secretKey = string
      })
    })
    supportUrl = string
  })
}
