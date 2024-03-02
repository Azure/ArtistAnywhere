###################################################################################
# Storage (https://learn.microsoft.com/azure/storage/common/storage-introduction) #
###################################################################################

storageAccounts = [
  {
    enable               = true
    name                 = "xstudio2"  # Name must be globally unique (lowercase alphanumeric)
    type                 = "StorageV2" # https://learn.microsoft.com/azure/storage/common/storage-account-overview
    tier                 = "Standard"  # https://learn.microsoft.com/azure/storage/common/storage-account-overview#performance-tiers
    redundancy           = "LRS"       # https://learn.microsoft.com/azure/storage/common/storage-redundancy
    enableHttpsOnly      = true        # https://learn.microsoft.com/azure/storage/common/storage-require-secure-transfer
    enableBlobNfsV3      = true        # https://learn.microsoft.com/azure/storage/blobs/network-file-system-protocol-support
    enableLargeFileShare = true        # https://learn.microsoft.com/azure/storage/files/storage-how-to-create-file-share#advanced
    privateEndpointTypes = [ # https://learn.microsoft.com/azure/storage/common/storage-private-endpoints
      "blob",
      "file"
    ]
    blobContainers = [ # https://learn.microsoft.com/azure/storage/blobs/storage-blobs-introduction
      {
        enable    = true
        name      = "content"
        fileSystem = {
          enable  = true
          rootAcl = "user::rwx,group::rwx,other::rwx"
        }
        loadFiles = false
      },
      {
        enable = true
        name   = "weka"
        fileSystem = {
          enable  = false
          rootAcl = ""
        }
        loadFiles = false
      }
    ]
    fileShares = [ # https://learn.microsoft.com/azure/storage/files/storage-files-introduction
      {
        enable         = true
        name           = "content"
        sizeGB         = 5120
        accessTier     = "TransactionOptimized"
        accessProtocol = "SMB"
        loadFiles      = false
      }
    ]
  },
  {
    enable               = true
    name                 = "xstudio3"    # Name must be globally unique (lowercase alphanumeric)
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
        enable         = true
        name           = "content"
        sizeGB         = 5120
        accessTier     = "Premium"
        accessProtocol = "NFS"
        loadFiles      = false
      }
    ]
  }
]
