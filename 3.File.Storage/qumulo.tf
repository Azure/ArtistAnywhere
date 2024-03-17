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

data azurerm_subnet storage_qumulo {
  count                = var.qumulo.enable ? 1 : 0
  name                 = var.existingNetwork.enable ? var.existingNetwork.subnetName : "StorageQumulo"
  resource_group_name  = data.azurerm_virtual_network.studio.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.studio.name
}

data local_file user {
  count    = var.qumulo.enable ? 1 : 0
  filename = "user.txt"
  depends_on = [
    terraform_data.user
  ]
}

resource terraform_data user {
  count = var.qumulo.enable ? 1 : 0
  provisioner local-exec {
    command = "az account show --query user.name --output tsv > user.txt"
  }
}

resource azurerm_resource_group qumulo {
  count    = var.qumulo.enable ? 1 : 0
  name     = var.existingNetwork.enable || local.rootRegion.nameSuffix == "" ? "${var.resourceGroupName}.Qumulo" : "${var.resourceGroupName}.${local.rootRegion.nameSuffix}.Qumulo"
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
        email = data.local_file.user[0].content
      }
      storageSku        = "Hot"
      initialCapacity   = var.qumulo.initialCapacity
      delegatedSubnetId = data.azurerm_subnet.storage_qumulo[0].id
      adminPassword     = var.qumulo.adminLogin.userPassword != "" || !module.global.keyVault.enable ? var.qumulo.adminLogin.userPassword : data.azurerm_key_vault_secret.admin_password[0].value
    }
  })
  schema_validation_enabled = false
}
