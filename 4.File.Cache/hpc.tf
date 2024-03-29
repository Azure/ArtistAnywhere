##############################################################################
# HPC Cache (https://learn.microsoft.com/azure/hpc-cache/hpc-cache-overview) #
##############################################################################

variable hpcCache {
  type = object({
    throughput = string
    size       = number
    mtuSize    = number
    ntpHost    = string
    dns = object({
      ipAddresses  = list(string)
      searchDomain = string
    })
    encryption = object({
      enable    = bool
      rotateKey = bool
    })
  })
}

data azuread_service_principal hpc_cache {
  count        = var.enableHPCCache ? 1 : 0
  display_name = "HPC Cache Resource Provider"
}

locals {
  blobStorageAccountNfs = !var.existingStorageBlobNfs.enable ? data.terraform_remote_state.storage.outputs.blobStorageAccountNfs : {
    name              = var.existingStorageBlobNfs.accountName
    resourceGroupName = var.existingStorageBlobNfs.resourceGroupName
  }
  storageCaches = distinct(var.existingNetwork.enable ? [
    for virtualNetwork in local.virtualNetworks : merge(var.hpcCache, {
      name              = var.cacheName
      nameSuffix        = ""
      regionName        = module.global.resourceLocation.region
      resourceGroupName = var.resourceGroupName
      virtualNetwork = {
        subnetId          = "/subscriptions/${data.azurerm_client_config.studio.subscription_id}/resourceGroups/${var.existingNetwork.resourceGroupName}/providers/Microsoft.Network/virtualNetworks/${var.existingNetwork.name}/subnets/${var.existingNetwork.subnetName}"
        dnsZoneName       = var.existingNetwork.privateDnsZoneName
        resourceGroupName = var.existingNetwork.resourceGroupName
      }
    }) if var.enableHPCCache
  ] : [
    for virtualNetwork in local.virtualNetworks : merge(var.hpcCache, {
      name              = "${var.cacheName}-${virtualNetwork.nameSuffix}"
      nameSuffix        = virtualNetwork.nameSuffix
      regionName        = virtualNetwork.regionName
      resourceGroupName = "${var.resourceGroupName}.${virtualNetwork.nameSuffix}"
      virtualNetwork = {
        subnetId          = "/subscriptions/${data.azurerm_client_config.studio.subscription_id}/resourceGroups/${virtualNetwork.resourceGroupName}/providers/Microsoft.Network/virtualNetworks/${virtualNetwork.name}/subnets/Cache"
        dnsZoneName       = data.terraform_remote_state.network.outputs.privateDns.name
        resourceGroupName = virtualNetwork.resourceGroupName
      }
    }) if var.enableHPCCache
  ])
  storageTargets = flatten([
    for storageCache in local.storageCaches : [
      for storageTarget in var.storageTargets : merge(storageTarget, {
        name                   = "${storageCache.name}-${storageTarget.name}"
        cacheName              = storageCache.name
        cacheResourceGroupName = storageCache.resourceGroupName
      }) if storageTarget.enable
    ]
  ])
}

resource azurerm_role_assignment storage_account_contributor {
  count                = var.enableHPCCache ? 1 : 0
  role_definition_name = "Storage Account Contributor" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#storage-account-contributor
  principal_id         = data.azuread_service_principal.hpc_cache[0].object_id
  scope                = "/subscriptions/${data.azurerm_client_config.studio.subscription_id}/resourceGroups/${local.blobStorageAccountNfs.resourceGroupName}/providers/Microsoft.Storage/storageAccounts/${local.blobStorageAccountNfs.name}"
}

resource azurerm_role_assignment storage_blob_data_contributor {
  count                = var.enableHPCCache ? 1 : 0
  role_definition_name = "Storage Blob Data Contributor" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#storage-blob-data-contributor
  principal_id         = data.azuread_service_principal.hpc_cache[0].object_id
  scope                = "/subscriptions/${data.azurerm_client_config.studio.subscription_id}/resourceGroups/${local.blobStorageAccountNfs.resourceGroupName}/providers/Microsoft.Storage/storageAccounts/${local.blobStorageAccountNfs.name}"
}

resource azurerm_hpc_cache studio {
  for_each = {
    for storageCache in local.storageCaches : storageCache.name => storageCache
  }
  name                = each.value.name
  resource_group_name = each.value.resourceGroupName
  location            = each.value.regionName
  subnet_id           = each.value.virtualNetwork.subnetId
  sku_name            = each.value.throughput
  cache_size_in_gb    = each.value.size
  mtu                 = each.value.mtuSize
  ntp_server          = each.value.ntpHost != "" ? each.value.ntpHost : null
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  dynamic dns {
    for_each = length(each.value.dns.ipAddresses) > 0 || each.value.dns.searchDomain != "" ? [1] : []
    content {
      servers       = each.value.dns.ipAddresses
      search_domain = each.value.dns.searchDomain != "" ? each.value.dns.searchDomain : null
    }
  }
  key_vault_key_id                           = each.value.encryption.enable ? data.azurerm_key_vault_key.cache_encryption[0].id : null
  automatically_rotate_key_to_latest_enabled = each.value.encryption.enable ? each.value.encryption.rotateKey : null
  depends_on = [
    azurerm_resource_group.cache_regions,
    azurerm_role_assignment.storage_account_contributor,
    azurerm_role_assignment.storage_blob_data_contributor
  ]
}

resource azurerm_hpc_cache_nfs_target storage {
  for_each = {
    for storageTarget in local.storageTargets : storageTarget.name => storageTarget if storageTarget.containerName == ""
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
    for storageTarget in local.storageTargets : storageTarget.name => storageTarget if storageTarget.containerName != ""
  }
  name                          = each.value.name
  resource_group_name           = each.value.cacheResourceGroupName
  cache_name                    = each.value.cacheName
  namespace_path                = each.value.clientPath
  usage_model                   = each.value.usageModel
  verification_timer_in_seconds = each.value.fileIntervals.verificationSeconds
  write_back_timer_in_seconds   = each.value.fileIntervals.writeBackSeconds
  storage_container_id          = "/subscriptions/${data.azurerm_client_config.studio.subscription_id}/resourceGroups/${each.value.resourceGroupName}/providers/Microsoft.Storage/storageAccounts/${each.value.hostName}/blobServices/default/containers/${each.value.containerName}"
  depends_on = [
    azurerm_hpc_cache.studio
  ]
}

############################################################################
# Private DNS (https://learn.microsoft.com/azure/dns/private-dns-overview) #
############################################################################

resource azurerm_private_dns_a_record cache_hpc {
  for_each = {
    for storageCache in local.storageCaches : storageCache.name => storageCache
  }
  name                = lower(each.value.name)
  resource_group_name = var.existingNetwork.enable ? var.existingNetwork.resourceGroupName : data.azurerm_private_dns_zone.studio.resource_group_name
  zone_name           = var.existingNetwork.enable ? var.existingNetwork.privateDnsZoneName : data.azurerm_private_dns_zone.studio.name
  records             = azurerm_hpc_cache.studio[each.value.name].mount_addresses
  ttl                 = var.dnsRecord.ttlSeconds
}

output hpcCacheDNS {
  value = !var.enableHPCCache ? null : [
    for dnsRecord in azurerm_private_dns_a_record.cache_hpc : {
      name    = dnsRecord.name
      fqdn    = dnsRecord.fqdn
      records = dnsRecord.records
    }
  ]
}
