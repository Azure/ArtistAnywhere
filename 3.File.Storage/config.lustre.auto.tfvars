##########################################################################################
# Managed Lustre (https://learn.microsoft.com/azure/azure-managed-lustre/amlfs-overview) #
##########################################################################################

lustre = {
  enable  = false
  name    = "xlab"
  tier    = "AMLFS-Durable-Premium-40" # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/managed_lustre_file_system#sku_name
  sizeTiB = 48                         # https://learn.microsoft.com/azure/azure-managed-lustre/create-file-system-resource-manager#file-system-type-and-size-options
  maintenanceWindow = {
    dayOfWeek    = "Saturday"
    utcStartTime = "00:00"
  }
  blobStorage = {
    enable            = false
    resourceGroupName = "ArtistAnywhere.Storage"
    accountName       = "xstudio1"
    containerName = {
      archive = "lustre"
      logging = "lustre-logging"
    }
    importPrefix = ""
  }
  encryption = {
    enable = false
  }
}
