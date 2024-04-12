######################################################################################################
# Data Lake Storage (https://learn.microsoft.com/azure/storage/blobs/data-lake-storage-introduction) #
######################################################################################################

resource azurerm_storage_account analytics {
  count                           = var.data.analytics.enable ? 1 : 0
  name                            = var.data.analytics.workspace.storageAccount.name
  resource_group_name             = azurerm_resource_group.data_analytics[0].name
  location                        = azurerm_resource_group.data_analytics[0].location
  account_kind                    = var.data.analytics.workspace.storageAccount.type
  account_replication_type        = var.data.analytics.workspace.storageAccount.redundancy
  account_tier                    = var.data.analytics.workspace.storageAccount.performance
  is_hns_enabled                  = true
  allow_nested_items_to_be_public = false
  network_rules {
    default_action = "Deny"
    ip_rules = [
      jsondecode(data.http.client_address.response_body).ip
    ]
  }
}

resource azurerm_role_assignment analytics {
  count                = var.data.analytics.enable ? 1 : 0
  role_definition_name = "Storage Blob Data Contributor" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#storage-blob-data-contributor
  principal_id         = data.azurerm_user_assigned_identity.studio.principal_id
  scope                = azurerm_storage_account.analytics[0].id
}

resource azurerm_storage_data_lake_gen2_filesystem analytics {
  count              = var.data.analytics.enable ? 1 : 0
  name               = azurerm_storage_account.analytics[0].name
  storage_account_id = azurerm_storage_account.analytics[0].id
  depends_on = [
    azurerm_role_assignment.analytics
  ]
}

data azurerm_private_dns_zone analytics_storage {
  count               = var.data.analytics.enable ? 1 : 0
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = data.terraform_remote_state.network.outputs.privateDns.resourceGroupName
}

resource azurerm_private_endpoint analytics_storage {
  count               = var.data.analytics.enable ? 1 : 0
  name                = "${var.data.analytics.workspace.storageAccount.name}-blob"
  resource_group_name = azurerm_resource_group.data_analytics[0].name
  location            = azurerm_resource_group.data_analytics[0].location
  subnet_id           = data.azurerm_subnet.data.id
  private_service_connection {
    name                           = azurerm_storage_account.analytics[0].name
    private_connection_resource_id = azurerm_storage_account.analytics[0].id
    is_manual_connection           = false
    subresource_names = [
      "blob"
    ]
  }
  private_dns_zone_group {
    name = azurerm_storage_account.analytics[0].name
    private_dns_zone_ids = [
      data.azurerm_private_dns_zone.analytics_storage[0].id
    ]
  }
}
