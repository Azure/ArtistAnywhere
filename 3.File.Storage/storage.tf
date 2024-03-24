###################################################################################
# Storage (https://learn.microsoft.com/azure/storage/common/storage-introduction) #
###################################################################################

variable storageAccounts {
  type = list(object({
    enable               = bool
    name                 = string
    type                 = string
    tier                 = string
    redundancy           = string
    enableHttpsOnly      = bool
    enableBlobNfsV3      = bool
    enableLargeFileShare = bool
    privateEndpointTypes = list(string)
    blobContainers = list(object({
      enable = bool
      name   = string
      fileSystem = object({
        enable  = bool
        rootAcl = string
      })
      loadFiles = bool
    }))
    fileShares = list(object({
      enable         = bool
      name           = string
      sizeGB         = number
      accessTier     = string
      accessProtocol = string
      loadFiles      = bool
    }))
  }))
}

locals {
  serviceEndpointSubnets = distinct(var.existingNetwork.enable ? flatten([
    for subnet in data.terraform_remote_state.network.outputs.storageEndpointSubnets : [
      var.existingNetwork.serviceEndpointSubnets
    ]
  ]) : data.terraform_remote_state.network.outputs.storageEndpointSubnets)
  privateEndpoints = flatten([
    for storageAccount in var.storageAccounts : [
      for privateEndpointType in storageAccount.privateEndpointTypes : {
        type               = privateEndpointType
        storageAccountName = storageAccount.name
        storageAccountId   = "${azurerm_resource_group.storage.id}/providers/Microsoft.Storage/storageAccounts/${storageAccount.name}"
        dnsZoneId          = "${data.azurerm_resource_group.dns.id}/providers/Microsoft.Network/privateDnsZones/privatelink.${privateEndpointType}.core.windows.net"
      }
    ] if storageAccount.enable
  ])
  blobStorageAccount = one([
    for storageAccount in azurerm_storage_account.studio : storageAccount if storageAccount.nfsv3_enabled == false
  ])
  blobStorageAccountNfs = one([
    for storageAccount in azurerm_storage_account.studio : storageAccount if storageAccount.nfsv3_enabled == true
  ])
  blobContainers = flatten([
    for storageAccount in var.storageAccounts : [
      for blobContainer in storageAccount.blobContainers : merge(blobContainer, {
        key                = "${storageAccount.name}-${blobContainer.name}"
        storageAccountName = storageAccount.name
      }) if blobContainer.enable
    ] if storageAccount.enable
  ])
  fileShares = flatten([
    for storageAccount in var.storageAccounts : [
      for fileShare in storageAccount.fileShares : merge(fileShare, {
        key                = "${storageAccount.name}-${fileShare.name}"
        storageAccountName = storageAccount.name
      }) if fileShare.enable
    ] if storageAccount.enable
  ])
}

resource azurerm_storage_account studio {
  for_each = {
    for storageAccount in var.storageAccounts : storageAccount.name => storageAccount if storageAccount.enable
  }
  name                            = each.value.name
  resource_group_name             = azurerm_resource_group.storage.name
  location                        = azurerm_resource_group.storage.location
  account_kind                    = each.value.type
  account_tier                    = each.value.tier
  account_replication_type        = each.value.redundancy
  enable_https_traffic_only       = each.value.enableHttpsOnly
  is_hns_enabled                  = each.value.enableBlobNfsV3
  nfsv3_enabled                   = each.value.enableBlobNfsV3
  large_file_share_enabled        = each.value.enableLargeFileShare ? true : null
  allow_nested_items_to_be_public = false
  network_rules {
    default_action = "Deny"
    virtual_network_subnet_ids = [
      for serviceEndpointSubnet in local.serviceEndpointSubnets :
        "/subscriptions/${data.azurerm_client_config.studio.subscription_id}/resourceGroups/${serviceEndpointSubnet.resourceGroupName}/providers/Microsoft.Network/virtualNetworks/${serviceEndpointSubnet.virtualNetworkName}/subnets/${serviceEndpointSubnet.name}"
    ]
    ip_rules = [
      jsondecode(data.http.client_address.response_body).ip
    ]
  }
}

resource azurerm_private_endpoint storage {
  for_each = {
    for privateEndpoint in local.privateEndpoints : "${privateEndpoint.storageAccountName}-${privateEndpoint.type}" => privateEndpoint
  }
  name                = "${each.value.storageAccountName}-${each.value.type}"
  resource_group_name = azurerm_resource_group.storage.name
  location            = azurerm_resource_group.storage.location
  subnet_id           = data.azurerm_subnet.storage.id
  private_service_connection {
    name                           = each.value.storageAccountName
    private_connection_resource_id = each.value.storageAccountId
    is_manual_connection           = false
    subresource_names = [
      each.value.type
    ]
  }
  private_dns_zone_group {
    name = each.value.storageAccountName
    private_dns_zone_ids = [
      each.value.dnsZoneId
    ]
  }
  depends_on = [
    azurerm_storage_account.studio
  ]
}

resource azurerm_role_assignment storage_contributor {
  for_each = {
    for storageAccount in var.storageAccounts : storageAccount.name => storageAccount if storageAccount.enable
  }
  role_definition_name = "Contributor" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#contributor
  principal_id         = data.azurerm_user_assigned_identity.studio.principal_id
  scope                = "${azurerm_resource_group.storage.id}/providers/Microsoft.Storage/storageAccounts/${each.value.name}"
  depends_on = [
    azurerm_storage_account.studio
  ]
}

resource azurerm_role_assignment storage_blob_data_owner {
  for_each = {
    for storageAccount in var.storageAccounts : storageAccount.name => storageAccount if storageAccount.enable
  }
  role_definition_name = "Storage Blob Data Owner" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#storage-blob-data-owner
  principal_id         = data.azurerm_client_config.studio.object_id
  scope                = "${azurerm_resource_group.storage.id}/providers/Microsoft.Storage/storageAccounts/${each.value.name}"
  depends_on = [
    azurerm_storage_account.studio
  ]
}

resource azurerm_storage_container core {
  for_each = {
    for blobContainer in local.blobContainers : blobContainer.key => blobContainer
  }
  name                 = each.value.name
  storage_account_name = each.value.storageAccountName
  depends_on = [
    azurerm_role_assignment.storage_blob_data_owner
  ]
}

resource terraform_data blob_container_file_system_access_default {
  for_each = {
    for blobContainer in local.blobContainers : blobContainer.key => blobContainer if blobContainer.fileSystem.enable
  }
  provisioner local-exec {
    command = "az storage fs access update-recursive --auth-mode login --account-name ${each.value.storageAccountName} --file-system ${each.value.name} --path / --acl default:${each.value.fileSystem.rootAcl}"
  }
  depends_on = [
    azurerm_storage_container.core
  ]
}

resource terraform_data blob_container_file_system_access_pre_load {
  for_each = {
    for blobContainer in local.blobContainers : blobContainer.key => blobContainer if blobContainer.fileSystem.enable
  }
  provisioner local-exec {
    command = "az storage fs access update-recursive --auth-mode login --account-name ${each.value.storageAccountName} --file-system ${each.value.name} --path / --acl ${each.value.fileSystem.rootAcl}"
  }
  depends_on = [
    azurerm_storage_container.core
  ]
}

resource terraform_data blob_container_load_root {
  for_each = {
    for blobContainer in local.blobContainers : blobContainer.key => blobContainer if blobContainer.loadFiles && var.fileLoadSource.enable && var.fileLoadSource.blobName == ""
  }
  provisioner local-exec {
    environment = {
      AZURE_STORAGE_AUTH_MODE = "login"
    }
    command = "az storage copy --source-account-name ${var.fileLoadSource.accountName} --source-account-key ${var.fileLoadSource.accountKey} --source-container ${var.fileLoadSource.containerName} --recursive --account-name ${each.value.storageAccountName} --destination-container ${each.value.name}"
  }
  depends_on = [
    terraform_data.blob_container_file_system_access_default,
    terraform_data.blob_container_file_system_access_pre_load
  ]
}

resource terraform_data blob_container_load_blob {
  for_each = {
    for blobContainer in local.blobContainers : blobContainer.key => blobContainer if blobContainer.loadFiles && var.fileLoadSource.enable && var.fileLoadSource.blobName != ""
  }
  provisioner local-exec {
    environment = {
      AZURE_STORAGE_AUTH_MODE = "login"
    }
    command = "az storage copy --source-account-name ${var.fileLoadSource.accountName} --source-account-key ${var.fileLoadSource.accountKey} --source-container ${var.fileLoadSource.containerName} --source-blob ${var.fileLoadSource.blobName} --recursive --account-name ${each.value.storageAccountName} --destination-container ${each.value.name} --destination-blob ${var.fileLoadSource.blobName}"
  }
  depends_on = [
    terraform_data.blob_container_file_system_access_default,
    terraform_data.blob_container_file_system_access_pre_load
  ]
}

resource terraform_data blob_container_file_system_access_post_load {
  for_each = {
    for blobContainer in local.blobContainers : blobContainer.key => blobContainer if blobContainer.fileSystem.enable && blobContainer.loadFiles
  }
  provisioner local-exec {
    command = "az storage fs access update-recursive --auth-mode login --account-name ${each.value.storageAccountName} --file-system ${each.value.name} --path / --acl ${each.value.fileSystem.rootAcl}"
  }
  depends_on = [
    azurerm_storage_container.core,
    terraform_data.blob_container_load_root,
    terraform_data.blob_container_load_blob
  ]
}

resource azurerm_storage_share core {
  for_each = {
    for fileShare in local.fileShares : fileShare.key => fileShare
  }
  name                 = each.value.name
  access_tier          = each.value.accessTier
  enabled_protocol     = each.value.accessProtocol
  storage_account_name = each.value.storageAccountName
  quota                = each.value.sizeGB
  depends_on = [
    azurerm_private_endpoint.storage
  ]
}

resource terraform_data file_share_load_root {
  for_each = {
    for fileShare in local.fileShares : fileShare.key => fileShare if fileShare.loadFiles && var.fileLoadSource.enable && var.fileLoadSource.blobName == ""
  }
  provisioner local-exec {
    environment = {
      AZURE_STORAGE_AUTH_MODE = "login"
    }
    command = "az storage copy --source-account-name ${var.fileLoadSource.accountName} --source-account-key ${var.fileLoadSource.accountKey} --source-container ${var.fileLoadSource.containerName} --recursive --account-name ${each.value.storageAccountName} --destination-share ${each.value.name}"
  }
  depends_on = [
    azurerm_storage_share.core
  ]
}

resource terraform_data file_share_load_blob {
  for_each = {
    for fileShare in local.fileShares : fileShare.key => fileShare if fileShare.loadFiles && var.fileLoadSource.enable && var.fileLoadSource.blobName != ""
  }
  provisioner local-exec {
    environment = {
      AZURE_STORAGE_AUTH_MODE = "login"
    }
    command = "az storage copy --source-account-name ${var.fileLoadSource.accountName} --source-account-key ${var.fileLoadSource.accountKey} --source-container ${var.fileLoadSource.containerName} --source-blob ${var.fileLoadSource.blobName} --recursive --account-name ${each.value.storageAccountName} --destination-share ${each.value.name} --destination-file-path ${var.fileLoadSource.blobName}"
  }
  depends_on = [
    azurerm_storage_share.core
  ]
}

output blobStorageAccount {
  value = {
    name              = local.blobStorageAccount.name
    resourceGroupName = local.blobStorageAccount.resource_group_name
  }
  sensitive = true
}

output blobStorageAccountNfs {
  value = {
    name              = local.blobStorageAccountNfs.name
    resourceGroupName = local.blobStorageAccountNfs.resource_group_name
  }
  sensitive = true
}
