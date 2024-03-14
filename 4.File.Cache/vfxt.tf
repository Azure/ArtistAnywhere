#################################################################################
# Avere vFXT (https://learn.microsoft.com/azure/avere-vfxt/avere-vfxt-overview) #
#################################################################################

variable vfxtCache {
  type = object({
    cluster = object({
      nodeSize      = number
      nodeCount     = number
      adminUsername = string
      adminPassword = string
      sshPublicKey  = string
      localTimezone = string
      enableDevMode = bool
      imageId = object({
        controller = string
        node       = string
      })
    })
    support = object({
      companyName      = string
      enableLogUpload  = bool
      enableProactive  = string
      rollingTraceFlag = string
    })
  })
}

data azurerm_virtual_network studio {
  name                = var.existingNetwork.enable ? var.existingNetwork.name : data.terraform_remote_state.network.outputs.virtualNetwork.name
  resource_group_name = var.existingNetwork.enable ? var.existingNetwork.resourceGroupName : data.terraform_remote_state.network.outputs.virtualNetwork.resourceGroupName
}

data azurerm_subnet cache {
  name                 = var.existingNetwork.enable ? var.existingNetwork.subnetName : "Cache"
  resource_group_name  = data.azurerm_virtual_network.studio.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.studio.name
}

locals {
  vfxtCache = merge({
    cluster = {
      adminUsername = var.vfxtCache.cluster.adminUsername != "" || !module.global.keyVault.enable ? var.vfxtCache.cluster.adminUsername : data.azurerm_key_vault_secret.admin_username[0].value
      adminPassword = var.vfxtCache.cluster.adminPassword != "" || !module.global.keyVault.enable ? var.vfxtCache.cluster.adminPassword : data.azurerm_key_vault_secret.admin_password[0].value
    }},
    var.vfxtCache
  )
  vfxtControllerAddress   = cidrhost(data.azurerm_subnet.cache.address_prefixes[0], 39)
  vfxtVServerFirstAddress = cidrhost(data.azurerm_subnet.cache.address_prefixes[0], 40)
  vfxtVServerAddressCount = 12
}

module vfxt_controller {
  count                          = var.enableHPCCache ? 0 : 1
  source                         = "github.com/Azure/Avere/src/terraform/modules/controller3"
  create_resource_group          = false
  resource_group_name            = azurerm_resource_group.cache_region[0].name
  location                       = module.global.primaryRegion.name
  admin_username                 = var.vfxtCache.cluster.adminUsername != "" || !module.global.keyVault.enable ? var.vfxtCache.cluster.adminUsername : data.azurerm_key_vault_secret.admin_username[0].value
  admin_password                 = var.vfxtCache.cluster.adminPassword != "" || !module.global.keyVault.enable ? var.vfxtCache.cluster.adminPassword : data.azurerm_key_vault_secret.admin_password[0].value
  ssh_key_data                   = var.vfxtCache.cluster.sshPublicKey != "" ? var.vfxtCache.cluster.sshPublicKey : null
  virtual_network_name           = data.azurerm_virtual_network.studio.name
  virtual_network_resource_group = data.azurerm_virtual_network.studio.resource_group_name
  virtual_network_subnet_name    = data.azurerm_subnet.cache.name
  static_ip_address              = local.vfxtControllerAddress
  image_id                       = var.vfxtCache.cluster.imageId.controller
  depends_on = [
    azurerm_resource_group.cache_region
  ]
}

resource avere_vfxt cache {
  count                           = var.enableHPCCache ? 0 : 1
  vfxt_cluster_name               = lower(var.cacheName)
  azure_resource_group            = azurerm_resource_group.cache_region[0].name
  location                        = module.global.primaryRegion.name
  node_cache_size                 = var.vfxtCache.cluster.nodeSize
  vfxt_node_count                 = var.vfxtCache.cluster.nodeCount
  image_id                        = var.vfxtCache.cluster.imageId.node
  azure_network_name              = data.azurerm_virtual_network.studio.name
  azure_network_resource_group    = data.azurerm_virtual_network.studio.resource_group_name
  azure_subnet_name               = data.azurerm_subnet.cache.name
  controller_address              = module.vfxt_controller[count.index].controller_address
  controller_admin_username       = module.vfxt_controller[count.index].controller_username
  controller_admin_password       = var.vfxtCache.cluster.adminPassword != "" || !module.global.keyVault.enable ? var.vfxtCache.cluster.adminPassword : data.azurerm_key_vault_secret.admin_password[0].value
  vfxt_admin_password             = var.vfxtCache.cluster.adminPassword != "" || !module.global.keyVault.enable ? var.vfxtCache.cluster.adminPassword : data.azurerm_key_vault_secret.admin_password[0].value
  vfxt_ssh_key_data               = var.vfxtCache.cluster.sshPublicKey != "" ? var.vfxtCache.cluster.sshPublicKey : null
  support_uploads_company_name    = var.vfxtCache.support.companyName
  enable_support_uploads          = var.vfxtCache.support.enableLogUpload
  enable_secure_proactive_support = var.vfxtCache.support.enableProactive
  enable_rolling_trace_data       = var.vfxtCache.support.rollingTraceFlag != ""
  rolling_trace_flag              = var.vfxtCache.support.rollingTraceFlag
  vserver_first_ip                = local.vfxtVServerFirstAddress
  vserver_ip_count                = local.vfxtVServerAddressCount
  timezone                        = var.vfxtCache.cluster.localTimezone
  node_size                       = var.vfxtCache.cluster.enableDevMode ? "unsupported_test_SKU" : "prod_sku"
  dynamic core_filer {
    for_each = {
      for storageTarget in var.storageTargets : storageTarget.name => storageTarget if storageTarget.enable
    }
    content {
      name               = core_filer.value["name"]
      fqdn_or_primary_ip = core_filer.value["hostName"]
      cache_policy       = core_filer.value["usageModel"]
      dynamic junction {
        for_each = core_filer.value["vfxtJunctions"]
        content {
          core_filer_export   = junction.value["storageExport"]
          export_subdirectory = junction.value["storagePath"]
          namespace_path      = junction.value["clientPath"]
        }
      }
    }
  }
  depends_on = [
    module.vfxt_controller
  ]
}

############################################################################
# Private DNS (https://learn.microsoft.com/azure/dns/private-dns-overview) #
############################################################################

resource azurerm_private_dns_a_record cache_vfxt {
  count               = var.enableHPCCache ? 0 : 1
  name                = lower(var.cacheName)
  resource_group_name = var.existingNetwork.enable ? var.existingNetwork.resourceGroupName : data.azurerm_private_dns_zone.studio.resource_group_name
  zone_name           = var.existingNetwork.enable ? var.existingNetwork.privateDnsZoneName : data.azurerm_private_dns_zone.studio.name
  records             = avere_vfxt.cache[0].vserver_ip_addresses
  ttl                 = var.dnsRecord.ttlSeconds
}

output vfxtCacheControllerAddress {
  value = var.enableHPCCache ? null : avere_vfxt.cache[0].controller_address
}

output vfxtCacheManagementAddress {
  value = var.enableHPCCache ? null : avere_vfxt.cache[0].vfxt_management_ip
}

output vfxtCacheDNS {
  value = var.enableHPCCache ? null : [
    for dnsRecord in azurerm_private_dns_a_record.cache_vfxt : {
      name    = dnsRecord.name
      fqdn    = dnsRecord.fqdn
      records = dnsRecord.records
    }
  ]
}
