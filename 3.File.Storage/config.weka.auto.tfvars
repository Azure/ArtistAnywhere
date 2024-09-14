#######################################################################################################
# Weka (https://azuremarketplace.microsoft.com/marketplace/apps/weka1652213882079.weka_data_platform) #
#######################################################################################################

weka = {
  enable   = false
  version  = "4.3.5"
  apiToken = ""
  name = {
    resource = "xstudio"
    display  = "Azure Artist Anywhere"
  }
  machine = {
    size  = "Standard_L8s_v3"
    count = 6
    image = {
      resourceGroupName = "ArtistAnywhere.Image"
      galleryName       = "xstudio"
      definitionName    = "Linux"
      versionId         = "0.0.0"
      plan = {
        publisher = ""
        product   = ""
        name      = ""
      }
    }
    osDisk = {
      storageType = "Standard_LRS"
      cachingType = "ReadOnly"
      sizeGB      = 0
    }
    dataDisk = {
      storageType = "Standard_LRS"
      cachingType = "None"
      sizeGB      = 1024
    }
    adminLogin = {
      userName      = ""
      userPassword  = ""
      sshKeyPublic  = ""
      sshKeyPrivate = ""
      passwordAuth = {
        disable = true
      }
    }
    terminateNotification = {
      enable       = true
      delayTimeout = "PT15M"
    }
  }
  network = {
    acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
      enable = true
    }
    dnsRecord = {
      name    = "storage"
      ttlSeconds = 300
    }
  }
  objectTier = {
    percent = 80
    storage = {
      accountName   = ""
      accountKey    = ""
      containerName = "weka"
    }
  }
  fileSystem = {
    name         = "default"
    groupName    = "default"
    autoScale    = false
    authRequired = false
    loadFiles    = false
  }
  dataProtection = {
    stripeWidth = 3
    parityLevel = 2
    hotSpare    = 1
  }
  healthExtension = {
    protocol    = "http"
    port        = 14000
    requestPath = "/ui"
  }
  license = {
    key = ""
    payGo = {
      planId    = ""
      secretKey = ""
    }
  }
  supportUrl = ""
}
