#######################################################################################################
# NetApp Files (https://learn.microsoft.com/azure/azure-netapp-files/azure-netapp-files-introduction) #
#######################################################################################################

netAppFiles = {
  enable = false
  name   = "xstudio"
  capacityPools = [
    {
      enable  = false
      name    = "CapacityPool"
      tier    = "Standard"
      sizeTiB = 2
      volumes = [
        {
          enable    = false
          name      = "Volume1"
          tier      = "Standard"
          sizeGiB   = 100
          mountPath = "volume1"
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
        },
        {
          enable    = false
          name      = "Volume2"
          tier      = "Standard"
          sizeGiB   = 1948
          mountPath = "volume2"
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
}
