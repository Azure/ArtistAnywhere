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

##########################
# Pre-Existing Resources #
##########################

existingNetwork = {
  enable             = false
  name               = ""
  subnetNameIdentity = ""
  subnetNameStorage  = ""
  resourceGroupName  = ""
  privateDNS = {
    zoneName          = ""
    resourceGroupName = ""
  }
}

activeDirectory = {
  enable = false
  domain = {
    name = "azure.studio"
  }
  machine = {
    ip   = "10.0.192.254"
    name = "WinADController"
    adminLogin = {
      userName     = ""
      userPassword = ""
    }
  }
}
