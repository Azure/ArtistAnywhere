##########################################################################################
# Managed Lustre (https://learn.microsoft.com/azure/azure-managed-lustre/amlfs-overview) #
##########################################################################################

variable lustre {
  type = object({
    enable     = bool
    name       = string
    tier       = string
    capacityTB = number
    blobStorage = object({
      accountName = string
      containerName = object({
        archive = string
        logging = string
      })
    })
    maintenanceWindow = object({
      dayOfWeek    = string
      utcStartTime = string
    })
    encryption = object({
      enable = bool
    })
  })
}

data external region {
  count   = var.lustre.enable ? 1 : 0
  program = ["az", "account", "list-locations", "--query", "[?name=='${lower(module.global.resourceLocation.region)}']|[0]"]
}

resource azurerm_resource_group lustre {
  count    = var.lustre.enable ? 1 : 0
  name     = local.rootRegion.nameSuffix == "" ? "${var.resourceGroupName}.Lustre" : "${var.resourceGroupName}.${local.rootRegion.nameSuffix}.Lustre"
  location = local.rootRegion.name
}

resource azurerm_managed_lustre_file_system lab {
  count                  = var.lustre.enable ? 1 : 0
  name                   = var.lustre.name
  resource_group_name    = azurerm_resource_group.lustre[0].name
  location               = #azurerm_resource_group.lustre[0].location
  sku_name               = var.lustre.tier
  storage_capacity_in_tb = var.lustre.capacityTB
  subnet_id              = data.azurerm_subnet.storage_region.id
  zones                  = data.external.region[0].result.availabilityZoneMappings
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  hsm_setting {
    container_id         = azurerm_storage_container.lustre[0].id
    logging_container_id = azurerm_storage_container.lustre_logging[0].id
  }
  maintenance_window {
    day_of_week        = var.lustre.maintenanceWindow.dayOfWeek
    time_of_day_in_utc = var.lustre.maintenanceWindow.utcStartTime
  }
  dynamic encryption_key {
    for_each = var.lustre.encryption.enable ? [1] : []
    content {
      source_vault_id = data.azurerm_key_vault.studio[0].id
      key_url         = data.azurerm_key_vault_key.data_encryption[0].id
    }
  }
}

resource azurerm_storage_container lustre {
  count                = var.lustre.enable ? 1 : 0
  name                 = var.lustre.blobStorage.containerName.archive
  storage_account_name = var.lustre.blobStorage.accountName
}

resource azurerm_storage_container lustre_logging {
  count                = var.lustre.enable ? 1 : 0
  name                 = var.lustre.blobStorage.containerName.logging
  storage_account_name = var.lustre.blobStorage.accountName
}
