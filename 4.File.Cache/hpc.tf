#############################################################################
# HPC Cache (https://learn.microsoft.com/azure/hpc-cache/hpc-cache-overview) #
##############################################################################

variable hpcCache {
  type = object({
    enable     = bool
    name       = string
    throughput = string
    size       = number
    mtuSize    = number
    ntpHost    = string
    dns = object({
      ipAddresses  = list(string)
      searchDomain = string
    })
  })
}

data azuread_service_principal hpc_cache {
  count        = var.hpcCache.enable ? 1 : 0
  display_name = "HPC Cache Resource Provider"
}

resource azurerm_role_assignment storage_account_contributor {
  count                = var.hpcCache.enable ? 1 : 0
  role_definition_name = "Storage Account Contributor" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/storage#storage-account-contributor
  principal_id         = data.azuread_service_principal.hpc_cache[0].object_id
  scope                = "/subscriptions/${module.global.subscriptionId}/resourceGroups/${local.nfsStorageAccount.resourceGroupName}/providers/Microsoft.Storage/storageAccounts/${local.nfsStorageAccount.name}"
}

resource azurerm_role_assignment storage_blob_data_contributor {
  count                = var.hpcCache.enable ? 1 : 0
  role_definition_name = "Storage Blob Data Contributor" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/storage#storage-blob-data-contributor
  principal_id         = data.azuread_service_principal.hpc_cache[0].object_id
  scope                = "/subscriptions/${module.global.subscriptionId}/resourceGroups/${local.nfsStorageAccount.resourceGroupName}/providers/Microsoft.Storage/storageAccounts/${local.nfsStorageAccount.name}"
}

resource time_sleep hpc_cache_storage_rbac {
  count           = var.hpcCache.enable ? 1 : 0
  create_duration = "30s"
  depends_on = [
    azurerm_role_assignment.storage_account_contributor,
    azurerm_role_assignment.storage_blob_data_contributor
  ]
}

resource azurerm_hpc_cache studio {
  count               = var.hpcCache.enable ? 1 : 0
  name                = var.hpcCache.name
  resource_group_name = azurerm_resource_group.cache.name
  location            = azurerm_resource_group.cache.location
  subnet_id           = data.azurerm_subnet.cache.id
  sku_name            = var.hpcCache.throughput
  cache_size_in_gb    = var.hpcCache.size
  mtu                 = var.hpcCache.mtuSize
  ntp_server          = var.hpcCache.ntpHost != "" ? var.hpcCache.ntpHost : null
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  dynamic dns {
    for_each = length(var.hpcCache.dns.ipAddresses) > 0 || var.hpcCache.dns.searchDomain != "" ? [1] : []
    content {
      servers       = var.hpcCache.dns.ipAddresses
      search_domain = var.hpcCache.dns.searchDomain != "" ? var.hpcCache.dns.searchDomain : null
    }
  }
}

resource azurerm_hpc_cache_nfs_target storage {
  for_each = {
    for storageTarget in var.storageTargets : storageTarget.name => storageTarget if var.hpcCache.enable && storageTarget.enable && storageTarget.containerName == ""
  }
  name                          = each.value.name
  resource_group_name           = each.value.resourceGroupName
  cache_name                    = each.value.cacheName
  target_host_name              = each.value.hostName
  usage_model                   = each.value.usageModel
  verification_timer_in_seconds = each.value.fileIntervals.verificationSeconds
  write_back_timer_in_seconds   = each.value.fileIntervals.writeBackSeconds
  dynamic namespace_junction {
    for_each = each.value.namespaceJunctions
    content {
      nfs_export     = namespace_junction.value["storageExport"]
      target_path    = namespace_junction.value["storagePath"]
      namespace_path = namespace_junction.value["clientPath"]
    }
  }
  depends_on = [
    azurerm_hpc_cache.studio
  ]
}

resource azurerm_hpc_cache_blob_nfs_target storage {
  for_each = {
    for storageTarget in var.storageTargets : storageTarget.name => storageTarget if var.hpcCache.enable && storageTarget.enable && storageTarget.containerName != ""
  }
  name                          = each.value.name
  resource_group_name           = each.value.cacheResourceGroupName
  cache_name                    = each.value.cacheName
  namespace_path                = each.value.clientPath
  usage_model                   = each.value.usageModel
  verification_timer_in_seconds = each.value.fileIntervals.verificationSeconds
  write_back_timer_in_seconds   = each.value.fileIntervals.writeBackSeconds
  storage_container_id          = "/subscriptions/${module.global.subscriptionId}/resourceGroups/${each.value.resourceGroupName}/providers/Microsoft.Storage/storageAccounts/${each.value.hostName}/blobServices/default/containers/${each.value.containerName}"
  depends_on = [
    azurerm_hpc_cache.studio,
    time_sleep.hpc_cache_storage_rbac
  ]
}

############################################################################
# Private DNS (https://learn.microsoft.com/azure/dns/private-dns-overview) #
############################################################################

resource azurerm_private_dns_a_record cache_hpc {
  count               = var.hpcCache.enable ? 1 : 0
  name                = var.dnsRecord.name
  resource_group_name = var.existingNetwork.enable ? var.existingNetwork.resourceGroupName : data.azurerm_private_dns_zone.studio.resource_group_name
  zone_name           = var.existingNetwork.enable ? var.existingNetwork.privateDns.zoneName : data.azurerm_private_dns_zone.studio.name
  records             = azurerm_hpc_cache.studio[0].mount_addresses
  ttl                 = var.dnsRecord.ttlSeconds
}

output hpcCacheDNS {
  value = var.hpcCache.enable ? {
    fqdn    = azurerm_private_dns_a_record.cache_hpc[0].fqdn
    records = azurerm_private_dns_a_record.cache_hpc[0].records
  } : null
}
