#######################################################################################################
# NetApp Files (https://learn.microsoft.com/azure/azure-netapp-files/azure-netapp-files-introduction) #
#######################################################################################################

netAppFiles = {
  enable = false
  name   = "xstudio"
  capacityPools = [
    {
      enable  = true
      name    = "Pool1"
      tier    = "Premium"
      sizeTiB = 1
      coolAccess = {
        enable = true
        period = 30
      }
      volumes = [
        {
          enable      = true
          name        = "Volume1"
          mountPath   = "volume1"
          sizeGiB     = 512
          permissions = 7777
          network = {
            features = "Standard"
            protocols = [
              "NFSv3"
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
                "NFSv3"
              ]
              allowedClients = [
                "0.0.0.0/0"
              ]
            }
          ]
        },
        {
          enable      = true
          name        = "Volume2"
          mountPath   = "volume2"
          sizeGiB     = 512
          permissions = 7777
          network = {
            features = "Standard"
            protocols = [
              "NFSv3"
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
}
