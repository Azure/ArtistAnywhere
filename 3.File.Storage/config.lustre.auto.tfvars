##########################################################################################
# Managed Lustre (https://learn.microsoft.com/azure/azure-managed-lustre/amlfs-overview) #
##########################################################################################

lustre = {
  enable     = false
  name       = "xlab"
  tier       = "AMLFS-Durable-Premium-40" # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/managed_lustre_file_system#sku_name
  capacityTB = 48                         # https://learn.microsoft.com/azure/azure-managed-lustre/create-file-system-resource-manager#file-system-type-and-size-options
  blobStorage = {
    accountName = "xstudio2"
    containerName = {
      archive = "lustre"
      logging = "lustre-logging"
    }
  }
  maintenanceWindow = {
    dayOfWeek    = "Saturday"
    utcStartTime = "00:00"
  }
  encryption = {
    enable = false
  }
}
