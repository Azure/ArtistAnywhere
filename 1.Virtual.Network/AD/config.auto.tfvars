resourceGroupName = "ArtistAnywhere.AD"

#################################################################################################################################################
# Active Directory (https://learn.microsoft.com/windows-server/identity/ad-ds/get-started/virtual-dc/active-directory-domain-services-overview) #
#################################################################################################################################################

activeDirectory = {
  domainName = "azure.studio"
  machine = {
    name = "WinADController"
    size = "Standard_D8as_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
    image = {
      publisher = "MicrosoftWindowsServer"
      product   = "WindowsServer"
      name      = "2022-Datacenter-Azure-Edition"
      version   = "Latest"
    }
    osDisk = {
      storageType = "Premium_LRS"
      cachingMode = "ReadWrite"
      sizeGB      = 0
    }
    adminLogin = {
      userName     = ""
      userPassword = ""
    }
  }
  network = {
    acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
      enable = true
    }
    staticAddress = "10.0.192.254"
  }
}

activeDirectoryClient = {
  enable     = false
  domainName = "azure.studio"
  serverName = "WinADController"
  machine = {
    name = "WinADClient"
    size = "Standard_D8as_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
    image = {
      publisher = "MicrosoftWindowsDesktop"
      product   = "Windows-10"
      name      = "Win10-22H2-Ent-G2"
      version   = "Latest"
    }
    osDisk = {
      storageType = "Premium_LRS"
      cachingMode = "ReadWrite"
      sizeGB      = 0
    }
    adminLogin = {
      userName     = ""
      userPassword = ""
    }
  }
  network = {
    acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
      enable = true
    }
  }
}
