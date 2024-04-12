############################################################################################
# Synapse Analytics (https://learn.microsoft.com/azure/synapse-analytics/overview-what-is) #
############################################################################################

resource azurerm_synapse_workspace analytics {
  count                                = var.data.analytics.enable ? 1 : 0
  name                                 = var.data.analytics.workspace.name
  resource_group_name                  = azurerm_resource_group.data_analytics[0].name
  location                             = azurerm_resource_group.data_analytics[0].location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.analytics[0].id
  sql_administrator_login              = var.data.analytics.workspace.adminLogin.userName != "" || !module.global.keyVault.enable ? var.data.analytics.workspace.adminLogin.userName : data.azurerm_key_vault_secret.admin_username[0].value
  sql_administrator_login_password     = var.data.analytics.workspace.adminLogin.userPassword != "" || !module.global.keyVault.enable ? var.data.analytics.workspace.adminLogin.userPassword : data.azurerm_key_vault_secret.admin_password[0].value
  azuread_authentication_only          = var.data.analytics.workspace.authentication.azureADOnly
  managed_resource_group_name          = "${azurerm_resource_group.data_analytics[0].name}.Managed"
  compute_subnet_id                    = data.azurerm_subnet.data.id
  purview_id                           = var.data.governance.enable ? azurerm_purview_account.data[0].id : null
  identity {
    type = "SystemAssigned, UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  dynamic customer_managed_key {
    for_each = var.data.analytics.workspace.encryption.enable && module.global.keyVault.enable ? [1] : []
    content {
      key_name                  = module.global.keyVault.keyName.dataEncryption
      key_versionless_id        = data.azurerm_key_vault_key.data_encryption[0].versionless_id
      user_assigned_identity_id = data.azurerm_user_assigned_identity.studio.id
    }
  }
}

resource azurerm_synapse_firewall_rule allow_admin {
  count                = var.data.analytics.enable ? 1 : 0
  name                 = var.data.analytics.workspace.name
  synapse_workspace_id = azurerm_synapse_workspace.analytics[0].id
  start_ip_address     = jsondecode(data.http.client_address.response_body).ip
  end_ip_address       = jsondecode(data.http.client_address.response_body).ip
}

resource azurerm_synapse_firewall_rule allow_azure {
  count                = var.data.analytics.enable ? 1 : 0
  name                 = "AllowAllWindowsAzureIps"
  synapse_workspace_id = azurerm_synapse_workspace.analytics[0].id
  start_ip_address     = "0.0.0.0"
  end_ip_address       = "0.0.0.0"
}

resource azurerm_private_dns_zone analytics {
  count               = var.data.analytics.enable ? 1 : 0
  name                = "privatelink.sql.azuresynapse.net"
  resource_group_name = azurerm_resource_group.data_analytics[0].name
}

resource azurerm_private_dns_zone_virtual_network_link analytics {
  count                 = var.data.analytics.enable ? 1 : 0
  name                  = "analytics"
  resource_group_name   = azurerm_private_dns_zone.analytics[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.analytics[0].name
  virtual_network_id    = data.azurerm_virtual_network.studio.id
}

resource azurerm_private_endpoint analytics {
  count               = var.data.analytics.enable ? 1 : 0
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
    name = azurerm_private_dns_zone_virtual_network_link.analytics[0].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.analytics[0].id
    ]
  }
}
