#######################################################################################
# Qumulo (https://learn.microsoft.com/azure/partner-solutions/qumulo/qumulo-overview) #
#######################################################################################

variable qumulo {
  type = object({
    enable          = bool
    accountName     = string
    initialCapacity = number
    adminLogin = object({
      userPassword = string
    })
  })
}

data external user {
  count   = var.qumulo.enable ? 1 : 0
  program = ["az", "account", "show", "--query", "user"]
}

data azurerm_subnet storage_qumulo {
  count                = var.qumulo.enable ? 1 : 0
  name                 = "StorageQumulo"
  resource_group_name  = data.azurerm_virtual_network.studio_region.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.studio_region.name
}

resource azurerm_resource_group qumulo {
  count    = var.qumulo.enable ? 1 : 0
  name     = local.rootRegion.nameSuffix == "" ? "${var.resourceGroupName}.Qumulo" : "${var.resourceGroupName}.${local.rootRegion.nameSuffix}.Qumulo"
  location = local.rootRegion.name
}

resource azapi_resource qumulo {
  count     = var.qumulo.enable ? 1 : 0
  name      = var.qumulo.accountName
  type      = "Qumulo.Storage/fileSystems@2024-01-30-preview"
  parent_id = azurerm_resource_group.qumulo[0].id
  location  = azurerm_resource_group.qumulo[0].location
  body = jsonencode({
    properties = {
      marketplaceDetails = {
        publisherId = "qumulo1584033880660"
        offerId     = "qumulo-saas-mpp"
        planId      = "azure-native-qumulo-hot-cold-iops-live"
      }
      userDetails = {
        email = data.external.user[0].result.name
      }
      storageSku        = "Hot"
      initialCapacity   = var.qumulo.initialCapacity
      delegatedSubnetId = data.azurerm_subnet.storage_qumulo[0].id
      adminPassword     = var.qumulo.adminLogin.userPassword != "" || !module.global.keyVault.enable ? var.qumulo.adminLogin.userPassword : data.azurerm_key_vault_secret.admin_password[0].value
    }
  })
  schema_validation_enabled = false
}
