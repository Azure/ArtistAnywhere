#######################################################################################################
# Weka (https://azuremarketplace.microsoft.com/marketplace/apps/weka1652213882079.weka_data_platform) #
#######################################################################################################

weka = {
  enable   = false
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
  }
  adminLogin = {
    userName     = ""
    userPassword = ""
    sshKeyPublic = ""
    passwordAuth = {
      disable = true
    }
  }
  network = {
    acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
      enable = true
    }
    dnsRecord = {
      name    = "content"
      ttlSeconds = 300
    }
  }
  terminateNotification = {
    enable       = true
    delayTimeout = "PT15M"
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
  osDisk = {
    storageType = "Standard_LRS"
    cachingType = "ReadOnly"
    sizeGB      = 0
  }
  dataDisk = {
    storageType = "Standard_LRS"
    cachingType = "None"
    sizeGB      = 256
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
