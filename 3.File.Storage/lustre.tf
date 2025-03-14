##########################################################################################
# Managed Lustre (https://learn.microsoft.com/azure/azure-managed-lustre/amlfs-overview) #
##########################################################################################

variable managedLustre {
  type = object({
    enable  = bool
    name    = string
    type    = string
    sizeTiB = number
    blobStorage = object({
      enable            = bool
      accountName       = string
      resourceGroupName = string
      containerName = object({
        archive = string
        logging = string
      })
      importPrefix = string
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

data azuread_service_principal lustre {
  count        = var.managedLustre.enable && var.managedLustre.blobStorage.enable ? 1 : 0
  display_name = "HPC Cache Resource Provider"
}

data azurerm_storage_account lustre {
  count               = var.managedLustre.enable && var.managedLustre.blobStorage.enable ? 1 : 0
  name                = var.managedLustre.blobStorage.accountName
  resource_group_name = var.managedLustre.blobStorage.resourceGroupName
}

resource azurerm_resource_group lustre {
  count    = var.managedLustre.enable ? 1 : 0
  name     = "${var.resourceGroupName}.Lustre"
  location = local.location
  tags = {
    AAA = basename(path.cwd)
  }
}

resource azurerm_role_assignment lustre_storage_account_contributor {
  count                = var.managedLustre.enable && var.managedLustre.blobStorage.enable ? 1 : 0
  role_definition_name = "Storage Account Contributor" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/storage#storage-account-contributor
  principal_id         = data.azuread_service_principal.lustre[0].object_id
  scope                = data.azurerm_storage_account.lustre[0].id
}

resource azurerm_role_assignment lustre_storage_blob_data_contributor {
  count                = var.managedLustre.enable && var.managedLustre.blobStorage.enable ? 1 : 0
  role_definition_name = "Storage Blob Data Contributor" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/storage#storage-blob-data-contributor
  principal_id         = data.azuread_service_principal.lustre[0].object_id
  scope                = data.azurerm_storage_account.lustre[0].id
}

resource time_sleep lustre_storage_rbac {
  count           = var.managedLustre.enable && var.managedLustre.blobStorage.enable ? 1 : 0
  create_duration = "30s"
  depends_on = [
    azurerm_role_assignment.lustre_storage_account_contributor,
    azurerm_role_assignment.lustre_storage_blob_data_contributor
  ]
}

resource azurerm_managed_lustre_file_system studio {
  count                  = var.managedLustre.enable ? 1 : 0
  name                   = var.managedLustre.name
  resource_group_name    = azurerm_resource_group.lustre[0].name
  location               = azurerm_resource_group.lustre[0].location
  sku_name               = var.managedLustre.type
  storage_capacity_in_tb = var.managedLustre.sizeTiB
  subnet_id              = data.azurerm_subnet.storage.id
  zones                  = data.azurerm_location.studio.zone_mappings[*].logical_zone
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  maintenance_window {
    day_of_week        = var.managedLustre.maintenanceWindow.dayOfWeek
    time_of_day_in_utc = var.managedLustre.maintenanceWindow.utcStartTime
  }
  dynamic encryption_key {
    for_each = var.managedLustre.encryption.enable ? [1] : []
    content {
      source_vault_id = data.azurerm_key_vault.studio.id
      key_url         = data.azurerm_key_vault_key.data_encryption.id
    }
  }
  dynamic hsm_setting {
    for_each = var.managedLustre.blobStorage.enable ? [1] : []
    content {
      container_id         = azurerm_storage_container.lustre[0].id
      logging_container_id = azurerm_storage_container.lustre_logging[0].id
      import_prefix        = var.managedLustre.blobStorage.importPrefix
    }
  }
  depends_on = [
    azurerm_storage_account.studio,
    time_sleep.lustre_storage_rbac
  ]
}

resource azurerm_storage_container lustre {
  count              = var.managedLustre.enable && var.managedLustre.blobStorage.enable ? 1 : 0
  name               = var.managedLustre.blobStorage.containerName.archive
  storage_account_id = data.azurerm_storage_account.lustre[0].id
}

resource azurerm_storage_container lustre_logging {
  count              = var.managedLustre.enable && var.managedLustre.blobStorage.enable ? 1 : 0
  name               = var.managedLustre.blobStorage.containerName.logging
  storage_account_id = data.azurerm_storage_account.lustre[0].id
}
