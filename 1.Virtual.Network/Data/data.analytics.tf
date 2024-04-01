##########################################################################################################
# Cosmos DB Analytical Store (https://learn.microsoft.com/azure/cosmos-db/analytical-store-introduction) #
##########################################################################################################

data azurerm_private_dns_zone analytics_storage {
  count               = var.cosmosDB.dataAnalytics.enable ? 1 : 0
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = data.terraform_remote_state.network.outputs.privateDns.resourceGroupName
}

resource azurerm_private_endpoint analytics_storage {
  count               = var.cosmosDB.dataAnalytics.enable ? 1 : 0
  name                = "${var.cosmosDB.dataAnalytics.workspace.storageAccount.name}-blob"
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

resource azurerm_storage_account analytics {
  count                           = var.cosmosDB.dataAnalytics.enable ? 1 : 0
  name                            = var.cosmosDB.dataAnalytics.workspace.storageAccount.name
  resource_group_name             = azurerm_resource_group.data_analytics[0].name
  location                        = azurerm_resource_group.data_analytics[0].location
  account_kind                    = var.cosmosDB.dataAnalytics.workspace.storageAccount.type
  account_replication_type        = var.cosmosDB.dataAnalytics.workspace.storageAccount.redundancy
  account_tier                    = var.cosmosDB.dataAnalytics.workspace.storageAccount.performance
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
  count                = var.cosmosDB.dataAnalytics.enable ? 1 : 0
  role_definition_name = "Storage Blob Data Contributor" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#storage-blob-data-contributor
  principal_id         = data.azurerm_user_assigned_identity.studio.principal_id
  scope                = azurerm_storage_account.analytics[0].id
}

resource azurerm_storage_data_lake_gen2_filesystem analytics {
  count              = var.cosmosDB.dataAnalytics.enable ? 1 : 0
  name               = azurerm_storage_account.analytics[0].name
  storage_account_id = azurerm_storage_account.analytics[0].id
  depends_on = [
    azurerm_role_assignment.analytics
  ]
}

resource azurerm_synapse_workspace analytics {
  count                                = var.cosmosDB.dataAnalytics.enable ? 1 : 0
  name                                 = var.cosmosDB.dataAnalytics.workspace.name
  resource_group_name                  = azurerm_resource_group.data_analytics[0].name
  location                             = azurerm_resource_group.data_analytics[0].location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.analytics[0].id
  sql_administrator_login              = var.cosmosDB.dataAnalytics.workspace.adminLogin.userName != "" || !module.global.keyVault.enable ? var.cosmosDB.dataAnalytics.workspace.adminLogin.userName : data.azurerm_key_vault_secret.admin_username[0].value
  sql_administrator_login_password     = var.cosmosDB.dataAnalytics.workspace.adminLogin.userPassword != "" || !module.global.keyVault.enable ? var.cosmosDB.dataAnalytics.workspace.adminLogin.userPassword : data.azurerm_key_vault_secret.admin_password[0].value
  azuread_authentication_only          = var.cosmosDB.dataAnalytics.workspace.authentication.azureADOnly
  identity {
    type = "SystemAssigned, UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
}

resource azurerm_synapse_firewall_rule allow_admin {
  count                = var.cosmosDB.dataAnalytics.enable ? 1 : 0
  name                 = var.cosmosDB.dataAnalytics.workspace.name
  synapse_workspace_id = azurerm_synapse_workspace.analytics[0].id
  start_ip_address     = jsondecode(data.http.client_address.response_body).ip
  end_ip_address       = jsondecode(data.http.client_address.response_body).ip
}

resource azurerm_synapse_firewall_rule allow_azure {
  count                = var.cosmosDB.dataAnalytics.enable ? 1 : 0
  name                 = "AllowAllWindowsAzureIps"
  synapse_workspace_id = azurerm_synapse_workspace.analytics[0].id
  start_ip_address     = "0.0.0.0"
  end_ip_address       = "0.0.0.0"
}

resource azurerm_private_dns_zone analytics {
  count               = var.cosmosDB.dataAnalytics.enable ? 1 : 0
  name                = "privatelink.sql.azuresynapse.net"
  resource_group_name = azurerm_resource_group.data_analytics[0].name
}

resource azurerm_private_dns_zone_virtual_network_link analytics {
  count               = var.cosmosDB.dataAnalytics.enable ? 1 : 0
  name                  = "analytics"
  resource_group_name   = azurerm_private_dns_zone.analytics[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.analytics[0].name
  virtual_network_id    = data.azurerm_virtual_network.studio.id
}

resource azurerm_private_endpoint analytics {
  count               = var.cosmosDB.dataAnalytics.enable ? 1 : 0
  name                = "${azurerm_synapse_workspace.analytics[0].name}-analytics"
  resource_group_name = azurerm_resource_group.data_analytics[0].name
  location            = azurerm_resource_group.data_analytics[0].location
  subnet_id           = data.azurerm_subnet.data.id
  private_service_connection {
    name                           = azurerm_synapse_workspace.analytics[0].name
    private_connection_resource_id = azurerm_synapse_workspace.analytics[0].id
    is_manual_connection           = false
    subresource_names = [
      "Sql"
    ]
  }
  private_dns_zone_group {
    name = azurerm_synapse_workspace.analytics[0].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.analytics[0].id
    ]
  }
  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.analytics
  ]
}
