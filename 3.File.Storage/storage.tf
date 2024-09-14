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
    extendedZone = object({
      enable = bool
    })
  }))
}

locals {
  storageAccounts = [
    for storageAccount in var.storageAccounts : merge(storageAccount, {
      resourceGroupName     = var.resourceGroupName
      resourceGroupLocation = storageAccount.extendedZone.enable && module.global.resourceLocation.extendedZone.enable ? module.global.resourceLocation.extendedZone.regionName : module.global.resourceLocation.regionName
      extendedZoneName      = storageAccount.extendedZone.enable && module.global.resourceLocation.extendedZone.enable ? module.global.resourceLocation.extendedZone.name : null
      storageAccountId      = "/subscriptions/${data.azurerm_client_config.studio.subscription_id}/resourceGroups/${var.resourceGroupName}/providers/Microsoft.Storage/storageAccounts/${storageAccount.name}"
      storageAccountName    = storageAccount.name
    }) if storageAccount.enable
  ]
  privateEndpoints = flatten([
    for storageAccount in local.storageAccounts : [
      for privateEndpointType in storageAccount.privateEndpointTypes : merge(storageAccount, {
        key       = "${storageAccount.name}-${privateEndpointType}"
        type      = privateEndpointType
        dnsZoneId = "${data.azurerm_resource_group.dns.id}/providers/Microsoft.Network/privateDnsZones/privatelink.${privateEndpointType}.core.windows.net"
      })
    ]
  ])
  blobContainers = flatten([
    for storageAccount in local.storageAccounts : [
      for blobContainer in storageAccount.blobContainers : merge(storageAccount, blobContainer, {
        key = "${storageAccount.name}-${blobContainer.name}"
      }) if blobContainer.enable
    ]
  ])
  fileShares = flatten([
    for storageAccount in local.storageAccounts : [
      for fileShare in storageAccount.fileShares : merge(storageAccount, fileShare, {
        key = "${storageAccount.name}-${fileShare.name}"
      }) if fileShare.enable
    ]
  ])
}

resource azurerm_role_assignment storage_blob_data_owner {
  for_each = {
    for storageAccount in local.storageAccounts : storageAccount.name => storageAccount
  }
  role_definition_name = "Storage Blob Data Owner" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/storage#storage-blob-data-owner
  principal_id         = data.azurerm_client_config.studio.object_id
  scope                = each.value.storageAccountId
  depends_on = [
    azurerm_storage_account.studio
  ]
}

resource azurerm_role_assignment storage_blob_data_contributor {
  for_each = {
    for storageAccount in local.storageAccounts : storageAccount.name => storageAccount
  }
  role_definition_name = "Storage Blob Data Contributor" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/storage#storage-blob-data-contributor
  principal_id         = data.azurerm_user_assigned_identity.studio.principal_id
  scope                = each.value.storageAccountId
  depends_on = [
    azurerm_storage_account.studio
  ]
}

resource time_sleep storage_rbac {
  for_each = {
    for storageAccount in local.storageAccounts : storageAccount.name => storageAccount
  }
  create_duration = "30s"
  depends_on = [
    azurerm_role_assignment.storage_blob_data_owner,
    azurerm_role_assignment.storage_blob_data_contributor
  ]
}

resource azurerm_storage_account studio {
  for_each = {
    for storageAccount in local.storageAccounts : storageAccount.name => storageAccount
  }
  name                            = each.value.name
  resource_group_name             = each.value.resourceGroupName
  location                        = each.value.resourceGroupLocation
  edge_zone                       = each.value.extendedZoneName
  account_kind                    = each.value.type
  account_tier                    = each.value.tier
  account_replication_type        = each.value.redundancy
  https_traffic_only_enabled      = each.value.enableHttpsOnly
  is_hns_enabled                  = each.value.enableBlobNfsV3
  nfsv3_enabled                   = each.value.enableBlobNfsV3
  large_file_share_enabled        = each.value.enableLargeFileShare ? true : null
  allow_nested_items_to_be_public = false
  network_rules {
    default_action = "Deny"
    ip_rules = [
      jsondecode(data.http.client_address.response_body).ip
    ]
    dynamic private_link_access {
      for_each = module.global.defender.storage.malwareScanning.enable ? [1] : []
      content {
        endpoint_tenant_id   = data.azurerm_client_config.studio.tenant_id
        endpoint_resource_id = "/subscriptions/${data.azurerm_client_config.studio.subscription_id}/providers/Microsoft.Security/datascanners/storageDataScanner"
      }
    }
  }
  depends_on = [
    azurerm_resource_group.storage
  ]
}

resource azurerm_storage_container core {
  for_each = {
    for blobContainer in local.blobContainers : blobContainer.key => blobContainer
  }
  name                 = each.value.name
  storage_account_name = each.value.storageAccountName
  depends_on = [
    time_sleep.storage_rbac
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

resource azurerm_private_endpoint storage {
  for_each = {
    for privateEndpoint in local.privateEndpoints : privateEndpoint.key => privateEndpoint if privateEndpoint.extendedZoneName == null
  }
  name                = each.value.key
  resource_group_name = each.value.resourceGroupName
  location            = each.value.resourceGroupLocation
  # edge_zone           = each.value.extendedZoneName != "" ? each.value.extendedZoneName : null
  subnet_id           = data.azurerm_subnet.storage_region.id
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
