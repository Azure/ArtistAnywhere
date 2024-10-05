dataLoad = {
  enable = false
  source = {
    accountName   = ""
    accountKey    = ""
    containerName = ""
  }
  machine = {
    name = "xstudio"
    size = "Standard_D8as_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
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
      type        = "Linux"
      storageType = "Premium_LRS"
      cachingType = "ReadOnly"
      sizeGB      = 0
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
  }
  network = {
    acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
      enable = true
    }
  }
}
