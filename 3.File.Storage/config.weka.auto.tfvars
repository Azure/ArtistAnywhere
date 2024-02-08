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
      id = "/subscriptions/5cc0d8f1-3643-410c-8646-1a2961134bd3/resourceGroups/ArtistAnywhere.Image/providers/Microsoft.Compute/galleries/xstudio/images/Linux/versions/0.1.0"
      plan = {
        enable    = false
        publisher = ""
        product   = ""
        name      = ""
      }
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
    enable  = true
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
    storageType = "Premium_LRS"
    cachingType = "None"
    sizeGB      = 0
  }
  dataDisk = {
    storageType = "Premium_LRS"
    cachingType = "ReadWrite"
    sizeGB      = 256
  }
  dataProtection = {
    stripeWidth = 3
    parityLevel = 2
    hotSpare    = 1
  }
  healthExtension = {
    enable      = true
    protocol    = "http"
    port        = 14000
    requestPath = "/ui"
  }
  adminLogin = {
    userName     = ""
    userPassword = ""
    sshPublicKey = "" # "ssh-rsa ..."
    passwordAuth = {
      disable = false
    }
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
