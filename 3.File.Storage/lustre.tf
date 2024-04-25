##########################################################################################
# Managed Lustre (https://learn.microsoft.com/azure/azure-managed-lustre/amlfs-overview) #
##########################################################################################

variable lustre {
  type = object({
    enable     = bool
    name       = string
    tier       = string
    capacityTB = number
    maintenanceWindow = object({
      dayOfWeek    = string
      utcStartTime = string
    })
    blobStorage = object({
      enable            = bool
      resourceGroupName = string
      accountName       = string
      containerName = object({
        archive = string
        logging = string
      })
      importPrefix = string
    })
    encryption = object({
      enable = bool
    })
  })
}

data azuread_service_principal lustre {
  count        = var.lustre.enable && var.lustre.blobStorage.enable ? 1 : 0
  display_name = "HPC Cache Resource Provider"
}

data azurerm_storage_account lustre {
  count               = var.lustre.enable && var.lustre.blobStorage.enable ? 1 : 0
  name                = var.lustre.blobStorage.accountName
  resource_group_name = var.lustre.blobStorage.resourceGroupName
}

resource azurerm_resource_group lustre {
  count    = var.lustre.enable ? 1 : 0
  name     = "${var.resourceGroupName}.Lustre"
  location = module.global.resourceLocation.region
}

resource azurerm_role_assignment storage_account_contributor {
  count                = var.lustre.enable && var.lustre.blobStorage.enable ? 1 : 0
  role_definition_name = "Storage Account Contributor" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#storage-account-contributor
  principal_id         = data.azuread_service_principal.lustre[0].object_id
  scope                = data.azurerm_storage_account.lustre[0].id
}

resource azurerm_role_assignment storage_blob_data_contributor {
  count                = var.lustre.enable && var.lustre.blobStorage.enable ? 1 : 0
  role_definition_name = "Storage Blob Data Contributor" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#storage-blob-data-contributor
  principal_id         = data.azuread_service_principal.lustre[0].object_id
  scope                = data.azurerm_storage_account.lustre[0].id
}

resource azurerm_managed_lustre_file_system lab {
  count                  = var.lustre.enable ? 1 : 0
  name                   = var.lustre.name
  resource_group_name    = azurerm_resource_group.lustre[0].name
  location               = azurerm_resource_group.lustre[0].location
  sku_name               = var.lustre.tier
  storage_capacity_in_tb = var.lustre.capacityTB
  subnet_id              = data.azurerm_subnet.storage_region.id
  zones                  = ["1"]
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
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
  dynamic hsm_setting {
    for_each = var.lustre.blobStorage.enable ? [1] : []
    content {
      container_id         = azurerm_storage_container.lustre[0].id
      logging_container_id = azurerm_storage_container.lustre_logging[0].id
      import_prefix        = var.lustre.blobStorage.importPrefix
    }
  }
  depends_on = [
    azurerm_storage_account.studio,
    azurerm_role_assignment.storage_account_contributor,
    azurerm_role_assignment.storage_blob_data_contributor
  ]
}

resource azurerm_storage_container lustre {
  count                = var.lustre.enable && var.lustre.blobStorage.enable ? 1 : 0
  name                 = var.lustre.blobStorage.containerName.archive
  storage_account_name = var.lustre.blobStorage.accountName
}

resource azurerm_storage_container lustre_logging {
  count                = var.lustre.enable && var.lustre.blobStorage.enable ? 1 : 0
  name                 = var.lustre.blobStorage.containerName.logging
  storage_account_name = var.lustre.blobStorage.accountName
}
