#######################################################################################################
# NetApp Files (https://learn.microsoft.com/azure/azure-netapp-files/azure-netapp-files-introduction) #
#######################################################################################################

netAppFiles = {
  enable = false
  name   = "xstudio"
  dnsRecord = {
    namePrefix = "netapp"
    ttlSeconds = 300
  }
  capacityPools = [
    {
      enable  = true
      name    = "Pool1"
      tier    = "Premium"
      sizeTiB = 2
      volumes = [
        {
          enable    = true
          name      = "Volume1"
          mountPath = "volume1"
          sizeGiB   = 2048
          network = {
            features = "Standard"
            protocols = [
              "NFSv3"
            ]
          }
          exportPolicies = [
            {
              ruleIndex  = 1
              readOnly   = false
              readWrite  = true
              rootAccess = true
              networkProtocols = [
                "NFSv3"
              ]
              allowedClients = [
                "0.0.0.0/0"
              ]
            }
          ]
        }
      ]
    }
  ]
  encryption = {
    enable = false
  }
  loadFiles = {
    enable = false
    virtualMachine ={
      size = "Standard_E8s_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
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
      network = {
        acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
          enable = true
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
      operatingSystem = {
        type = "Linux"
        disk = {
          storageType = "Standard_LRS"
          cachingType = "ReadOnly"
          sizeGB      = 0
        }
      }
      extension = {
        custom = {
          enable   = true
          name     = "Initialize"
          fileName = "netapp.sh"
          parameters = {
          }
        }
      }
    }
  }
}
