#######################################################################################################
# NetApp Files (https://learn.microsoft.com/azure/azure-netapp-files/azure-netapp-files-introduction) #
#######################################################################################################

netAppFiles = {
  enable = false
  name   = "hpcai"
  capacityPools = [
    {
      enable  = true
      name    = "Pool1"
      type    = "Premium"
      sizeTiB = 1
      coolAccess = {
        enable = true
        period = 31
      }
      volumes = [
        {
          enable      = true
          name        = "Data"
          path        = "data"
          sizeGiB     = 640
          enableLarge = false
          permissions = 777
          network = {
            features = "Standard"
            protocols = [
              "NFSv3",
              # "CIFS"
            ]
          }
          exportPolicies = [
            {
              ruleIndex  = 1
              ownerMode  = "Restricted"
              readOnly   = false
              readWrite  = true
              rootAccess = true
              networkProtocols = [
                "NFSv3",
                # "CIFS"
              ]
              allowedClients = [
                "0.0.0.0/0"
              ]
            }
          ]
        },
        {
          enable      = true
          name        = "Tools"
          path        = "tools"
          sizeGiB     = 128
          enableLarge = false
          permissions = 777
          network = {
            features = "Standard"
            protocols = [
              "NFSv3",
              # "CIFS"
            ]
          }
          exportPolicies = [
            {
              ruleIndex  = 1
              ownerMode  = "Restricted"
              readOnly   = false
              readWrite  = true
              rootAccess = true
              networkProtocols = [
                "NFSv3",
                # "CIFS"
              ]
              allowedClients = [
                "0.0.0.0/0"
              ]
            }
          ]
        },
        {
          enable      = true
          name        = "Shared"
          path        = "shared"
          sizeGiB     = 128
          enableLarge = false
          permissions = 777
          network = {
            features = "Standard"
            protocols = [
              "NFSv3",
              # "CIFS"
            ]
          }
          exportPolicies = [
            {
              ruleIndex  = 1
              ownerMode  = "Restricted"
              readOnly   = false
              readWrite  = true
              rootAccess = true
              networkProtocols = [
                "NFSv3",
                # "CIFS"
              ]
              allowedClients = [
                "0.0.0.0/0"
              ]
            }
          ]
        },
        {
          enable      = true
          name        = "Scratch"
          path        = "scratch"
          sizeGiB     = 128
          enableLarge = false
          permissions = 777
          network = {
            features = "Standard"
            protocols = [
              "NFSv3",
              # "CIFS"
            ]
          }
          exportPolicies = [
            {
              ruleIndex  = 1
              ownerMode  = "Restricted"
              readOnly   = false
              readWrite  = true
              rootAccess = true
              networkProtocols = [
                "NFSv3",
                # "CIFS"
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
  backup = {
    enable = false
    name   = "hpcai"
    policy = {
      enable = true
      name   = "Default"
      retention = {
        daily   = 2
        weekly  = 1
        monthly = 1
      }
    }
  }
}
