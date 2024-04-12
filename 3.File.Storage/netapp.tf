#######################################################################################################
# NetApp Files (https://learn.microsoft.com/azure/azure-netapp-files/azure-netapp-files-introduction) #
#######################################################################################################

variable netApp {
  type = object({
    enable      = bool
    accountName = string
    capacityPools = list(object({
      enable       = bool
      name         = string
      sizeTiB      = number
      serviceLevel = string
      volumes = list(object({
        enable       = bool
        name         = string
        sizeGB       = number
        serviceLevel = string
        mountPath    = string
        protocols    = list(string)
        exportPolicies = list(object({
          ruleIndex      = number
          readOnly       = bool
          readWrite      = bool
          rootAccess     = bool
          protocols      = list(string)
          allowedClients = list(string)
        }))
      }))
    }))
  })
}

data azurerm_subnet storage_netapp {
  count                = var.netApp.enable ? 1 : 0
  name                 = "StorageNetApp"
  resource_group_name  = data.azurerm_virtual_network.studio_region.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.studio_region.name
}

locals {
  netAppVolumes = flatten([
    for capacityPool in var.netApp.capacityPools : [
      for volume in capacityPool.volumes : merge(volume, {
        capacityPoolName = capacityPool.name
      }) if volume.enable
    ] if var.netApp.enable && capacityPool.enable
  ])
}

resource azurerm_resource_group netapp {
  count    = var.netApp.enable ? 1 : 0
  name     = local.rootRegion.nameSuffix == "" ? "${var.resourceGroupName}.NetApp" : "${var.resourceGroupName}.${local.rootRegion.nameSuffix}.NetApp"
  location = local.rootRegion.name
}

resource azurerm_netapp_account storage {
  count               = var.netApp.enable ? 1 : 0
  name                = var.netApp.accountName
  resource_group_name = azurerm_resource_group.netapp[0].name
  location            = azurerm_resource_group.netapp[0].location
}

resource azurerm_netapp_pool storage {
  for_each = {
    for capacityPool in var.netApp.capacityPools : capacityPool.name => capacityPool if var.netApp.enable && capacityPool.enable
  }
  name                = each.value.name
  resource_group_name = azurerm_resource_group.netapp[0].name
  location            = azurerm_resource_group.netapp[0].location
  size_in_tb          = each.value.sizeTiB
  service_level       = each.value.serviceLevel
  account_name        = var.netApp.accountName
  depends_on = [
    azurerm_netapp_account.storage
  ]
}

resource azurerm_netapp_volume storage {
  for_each = {
    for volume in local.netAppVolumes : "${volume.capacityPoolName}-${volume.name}" => volume
  }
  name                = each.value.name
  resource_group_name = azurerm_resource_group.netapp[0].name
  location            = azurerm_resource_group.netapp[0].location
  storage_quota_in_gb = each.value.sizeGB
  service_level       = each.value.serviceLevel
  volume_path         = each.value.mountPath
  protocols           = each.value.protocols
  pool_name           = each.value.capacityPoolName
  account_name        = var.netApp.accountName
  subnet_id           = data.azurerm_subnet.storage_netapp[0].id
  dynamic export_policy_rule {
    for_each = each.value.exportPolicies
    content {
      rule_index          = export_policy_rule.value["ruleIndex"]
      unix_read_only      = export_policy_rule.value["readOnly"]
      unix_read_write     = export_policy_rule.value["readWrite"]
      root_access_enabled = export_policy_rule.value["rootAccess"]
      protocols_enabled   = export_policy_rule.value["protocols"]
      allowed_clients     = export_policy_rule.value["allowedClients"]
    }
  }
  depends_on = [
    azurerm_netapp_pool.storage
  ]
}
