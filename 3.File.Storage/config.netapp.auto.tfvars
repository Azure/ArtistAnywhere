#######################################################################################################
# NetApp Files (https://learn.microsoft.com/azure/azure-netapp-files/azure-netapp-files-introduction) #
#######################################################################################################

netApp = {
  enable      = false
  accountName = "xstudio"
  capacityPools = [
    {
      enable       = false
      name         = "CapacityPool"
      sizeTiB      = 4
      serviceLevel = "Standard"
      volumes = [
        {
          enable       = false
          name         = "Content"
          sizeGB       = 4096
          serviceLevel = "Standard"
          mountPath    = "content"
          protocols = [
            "NFSv3"
          ]
          exportPolicies = [
            {
              ruleIndex  = 1
              readOnly   = false
              readWrite  = true
              rootAccess = true
              protocols = [
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
}
