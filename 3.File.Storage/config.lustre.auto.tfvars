##########################################################################################
# Managed Lustre (https://learn.microsoft.com/azure/azure-managed-lustre/amlfs-overview) #
##########################################################################################

managedLustre = {
  enable  = false
  name    = "xstudio"
  type    = "AMLFS-Durable-Premium-40" # https://learn.microsoft.com/azure/azure-managed-lustre/create-file-system-resource-manager#file-system-type-and-size-options
  sizeTiB = 48
  blobStorage = {
    enable            = false
    accountName       = "xstudio1"
    resourceGroupName = "ArtistAnywhere.Storage"
    containerName = {
      archive = "lustre"
      logging = "lustre-logging"
    }
    importPrefix = "/"
  }
  maintenanceWindow = {
    dayOfWeek    = "Sunday"
    utcStartTime = "00:00"
  }
  encryption = {
    enable = false
  }
}
