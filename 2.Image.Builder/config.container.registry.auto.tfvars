######################################################################################################
# Container Registry (https://learn.microsoft.com/azure/container-registry/container-registry-intro) #
######################################################################################################

containerRegistry = {
  enable = false
  name   = "xstudio"
  sku    = "Premium"
  adminUser = {
    enable = true
  }
  zoneRedundancy = {
    enable = false
  }
}
