resourceGroupName = "ArtistAnywhere.Storage" # Alphanumeric, underscores, hyphens, periods and parenthesis are allowed

regionName = "" # Optional default region override

###################################################################################
# Storage (https://learn.microsoft.com/azure/storage/common/storage-introduction) #
###################################################################################

storageAccounts = [
  {
    enable               = false
    name                 = "xstudio1"         # Name must be globally unique (lowercase alphanumeric)
    type                 = "BlockBlobStorage" # https://learn.microsoft.com/azure/storage/common/storage-account-overview
    tier                 = "Premium"          # https://learn.microsoft.com/azure/storage/common/storage-account-overview#performance-tiers
    redundancy           = "LRS"              # https://learn.microsoft.com/azure/storage/common/storage-redundancy
    enableHttpsOnly      = true               # https://learn.microsoft.com/azure/storage/common/storage-require-secure-transfer
    enableBlobNfsV3      = true               # https://learn.microsoft.com/azure/storage/blobs/network-file-system-protocol-support
    enableLargeFileShare = false              # https://learn.microsoft.com/azure/storage/files/storage-how-to-create-file-share#advanced
    privateEndpointTypes = [ # https://learn.microsoft.com/azure/storage/common/storage-private-endpoints
      "blob"
    ]
    blobContainers = [ # https://learn.microsoft.com/azure/storage/blobs/storage-blobs-introduction
      {
        enable = true
        name   = "storage"
      }
    ]
    fileShares = [ # https://learn.microsoft.com/azure/storage/files/storage-files-introduction
    ]
    extendedZone = {
      enable = false
    }
  },
  {
    enable               = false
    name                 = "xstudio2"    # Name must be globally unique (lowercase alphanumeric)
    type                 = "FileStorage" # https://learn.microsoft.com/azure/storage/common/storage-account-overview
    tier                 = "Premium"     # https://learn.microsoft.com/azure/storage/common/storage-account-overview#performance-tiers
    redundancy           = "LRS"         # https://learn.microsoft.com/azure/storage/common/storage-redundancy
    enableHttpsOnly      = false         # https://learn.microsoft.com/azure/storage/common/storage-require-secure-transfer
    enableBlobNfsV3      = false         # https://learn.microsoft.com/azure/storage/blobs/network-file-system-protocol-support
    enableLargeFileShare = true          # https://learn.microsoft.com/azure/storage/files/storage-how-to-create-file-share#advanced
    privateEndpointTypes = [ # https://learn.microsoft.com/azure/storage/common/storage-private-endpoints
      "file"
    ]
    blobContainers = [ # https://learn.microsoft.com/azure/storage/blobs/storage-blobs-introduction
    ]
    fileShares = [ # https://learn.microsoft.com/azure/storage/files/storage-files-introduction
      {
        enable         = false
        name           = "storage"
        sizeGB         = 5120
        accessTier     = "Premium"
        accessProtocol = "NFS"
      }
    ]
    extendedZone = {
      enable = false
    }
  }
]

############################################################################
# Private DNS (https://learn.microsoft.com/azure/dns/private-dns-overview) #
############################################################################

dnsRecord = {
  name       = "storage"
  ttlSeconds = 300
}

#################################################################################################################################################
# Active Directory (https://learn.microsoft.com/windows-server/identity/ad-ds/get-started/virtual-dc/active-directory-domain-services-overview) #
#################################################################################################################################################

activeDirectory = {
  enable     = false
  domainName = "azure.studio"
  machine = {
    name = "WinADDC"
    size = "Standard_D8as_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
    image = {
      publisher = "MicrosoftWindowsServer"
      product   = "WindowsServer"
      name      = "2022-Datacenter-Azure-Edition"
      version   = "Latest"
    }
    osDisk = {
      storageType = "Premium_LRS"
      cachingType = "ReadWrite"
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
    staticAddress = "10.1.192.254"
  }
}

activeDirectoryClient = {
  enable      = false
  domainName  = "azure.studio"
  serverName  = "WinADDC"
  orgUnitPath = ""
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
      cachingType = "ReadWrite"
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

##########################
# Pre-Existing Resources #
##########################

existingNetwork = {
  enable             = false
  name               = ""
  subnetNameIdentity = ""
  subnetNameStorage  = ""
  resourceGroupName  = ""
  privateDns = {
    zoneName          = ""
    resourceGroupName = ""
  }
}
