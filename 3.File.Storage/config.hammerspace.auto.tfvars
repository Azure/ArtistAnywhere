#######################################################################################################
# Hammerspace (https://azuremarketplace.microsoft.com/marketplace/apps/hammerspace.hammerspace_4_6_5) #
#######################################################################################################

hammerspace = {
  namePrefix = ""
  domainName = ""
  metadata = {
    machine = {
      namePrefix = "Anvil"
      size       = "Standard_E4as_v4"
      count      = 1 # Set to 2 (or more) to enable high availability
    }
    network = {
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
      }
    }
    osDisk = {
      storageType = "Premium_LRS"
      cachingType = "ReadWrite"
      sizeGB      = 128
    }
    dataDisk = {
      storageType = "Premium_LRS"
      cachingType = "None"
      sizeGB      = 256
    }
    adminLogin = {
      userName     = ""
      userPassword = ""
      sshPublicKey = "" # "ssh-rsa ..."
      passwordAuth = {
        disable = false
      }
    }
  }
  data = {
    machine = {
      namePrefix = "DSX"
      size       = "Standard_F2s_v2"
      count      = 2
    }
    network = {
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
      }
    }
    osDisk = {
      storageType = "Premium_LRS"
      cachingType = "ReadWrite"
      sizeGB      = 128
    }
    dataDisk = {
      storageType = "Premium_LRS"
      cachingType = "None"
      enableRaid0 = false
      sizeGB      = 256
      count       = 2
    }
    adminLogin = {
      userName     = ""
      userPassword = ""
      sshPublicKey = "" # "ssh-rsa ..."
      passwordAuth = {
        disable = false
      }
    }
  }
}
