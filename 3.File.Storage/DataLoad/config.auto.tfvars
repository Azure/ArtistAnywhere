resourceGroupName = "AAA.Storage.DataLoad"

#########################################################################
# Virtual Machines (https://learn.microsoft.com/azure/virtual-machines) #
#########################################################################

dataLoad = {
  mount = {
    type    = "nfs" # "lustre"
    path    = "/mnt/data"
    target  = "10.1.194.4:/data" # 10.1.193.24@tcp:/lustrefs
    options = "vers=3" # "noatime"
  }
  machine = {
    name = "hpcai"
    size = "Standard_D8as_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
    image = {
      publisher = ""
      product   = ""
      name      = ""
      version   = ""
    }
    osDisk = {
      storageType = "Premium_LRS"
      cachingMode = "ReadWrite"
      sizeGB      = 0
    }
    adminLogin = {
      userName     = ""
      userPassword = ""
      sshKeyPublic = ""
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

########################
# Brownfield Resources #
########################

virtualNetwork = {
  name              = "HPC"
  subnetName        = "Storage"
  resourceGroupName = "AAA.Network.WestUS"
  privateDNS = {
    zoneName          = "azure.hpc"
    resourceGroupName = "AAA.Network"
  }
}
