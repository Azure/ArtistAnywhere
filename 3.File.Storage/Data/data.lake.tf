######################################################################################################
# Data Lake Storage (https://learn.microsoft.com/azure/storage/blobs/data-lake-storage-introduction) #
######################################################################################################

resource azurerm_storage_account datalake {
  name                            = var.data.lake.storageAccount.name
  resource_group_name             = azurerm_resource_group.data.name
  location                        = azurerm_resource_group.data.location
  account_kind                    = var.data.lake.storageAccount.type
  account_replication_type        = var.data.lake.storageAccount.redundancy
  account_tier                    = var.data.lake.storageAccount.performance
  is_hns_enabled                  = true
  allow_nested_items_to_be_public = false
  network_rules {
    default_action = "Deny"
    ip_rules = [
      jsondecode(data.http.client_address.response_body).ip
    ]
  }
}

resource azurerm_role_assignment datalake {
  role_definition_name = "Storage Blob Data Owner" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#storage-blob-data-owner
  principal_id         = data.azurerm_user_assigned_identity.studio.principal_id
  scope                = azurerm_storage_account.datalake.id
}

resource azurerm_storage_data_lake_gen2_filesystem studio {
  name               = azurerm_storage_account.datalake.name
  storage_account_id = azurerm_storage_account.datalake.id
  depends_on = [
    azurerm_role_assignment.datalake
  ]
}

resource azurerm_storage_data_lake_gen2_path studio {
  for_each = {
    for path in var.data.lake.paths : path => path
  }
  path               = each.value
  filesystem_name    = azurerm_storage_data_lake_gen2_filesystem.studio.name
  storage_account_id = azurerm_storage_account.datalake.id
  resource           = "directory"
}

data azurerm_private_dns_zone datalake {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = data.terraform_remote_state.network.outputs.privateDns.resourceGroupName
}

resource azurerm_private_endpoint datalake {
  name                = "${var.data.lake.storageAccount.name}-blob"
  resource_group_name = azurerm_resource_group.data.name
  location            = azurerm_resource_group.data.location
  subnet_id           = data.azurerm_subnet.data.id
  private_service_connection {
    name                           = azurerm_storage_account.datalake.name
    private_connection_resource_id = azurerm_storage_account.datalake.id
    is_manual_connection           = false
    subresource_names = [
      "blob"
    ]
  }
  private_dns_zone_group {
    name = azurerm_storage_account.datalake.name
    private_dns_zone_ids = [
      data.azurerm_private_dns_zone.datalake.id
    ]
  }
}
