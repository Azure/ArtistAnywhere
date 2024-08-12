############################################################################################
# Synapse Analytics (https://learn.microsoft.com/azure/synapse-analytics/overview-what-is) #
############################################################################################

resource azurerm_resource_group data_analytics_synapse {
  count    = var.data.analytics.synapse.enable ? 1 : 0
  name     = "${azurerm_resource_group.data.name}Analytics.Synapse"
  location = azurerm_resource_group.data.location
}

resource azurerm_synapse_workspace studio {
  count                                = var.data.analytics.synapse.enable ? 1 : 0
  name                                 = var.data.analytics.workspace.name
  resource_group_name                  = azurerm_resource_group.data_analytics_synapse[0].name
  location                             = azurerm_resource_group.data_analytics_synapse[0].location
  managed_resource_group_name          = "${azurerm_resource_group.data_analytics_synapse[0].name}.Managed"
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.studio.id
  compute_subnet_id                    = data.azurerm_subnet.data.id
  purview_id                           = var.data.governance.enable ? azurerm_purview_account.data_governance[0].id : null
  sql_administrator_login              = var.data.analytics.workspace.adminLogin.userName != "" ? var.data.analytics.workspace.adminLogin.userName : data.azurerm_key_vault_secret.admin_username.value
  sql_administrator_login_password     = var.data.analytics.workspace.adminLogin.userPassword != "" ? var.data.analytics.workspace.adminLogin.userPassword : data.azurerm_key_vault_secret.admin_password.value
  identity {
    type = "SystemAssigned, UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  github_repo {
    account_name    = "Azure"
    repository_name = "ArtistAnywhere"
    branch_name     = "main"
    root_folder     = "/1.Virtual.Network/Data/SynapseStudio"
  }
  dynamic customer_managed_key {
    for_each = var.data.analytics.workspace.encryption.enable ? [1] : []
    content {
      key_name                  = module.global.keyVault.keyName.dataEncryption
      key_versionless_id        = data.azurerm_key_vault_key.data_encryption[0].versionless_id
      user_assigned_identity_id = data.azurerm_user_assigned_identity.studio.id
    }
  }
}

resource azurerm_synapse_firewall_rule allow_admin {
  count                = var.data.analytics.synapse.enable ? 1 : 0
  name                 = var.data.analytics.workspace.name
  synapse_workspace_id = azurerm_synapse_workspace.studio[0].id
  start_ip_address     = jsondecode(data.http.client_address.response_body).ip
  end_ip_address       = jsondecode(data.http.client_address.response_body).ip
}

resource azurerm_synapse_firewall_rule allow_azure {
  count                = var.data.analytics.synapse.enable ? 1 : 0
  name                 = "AllowAllWindowsAzureIps"
  synapse_workspace_id = azurerm_synapse_workspace.studio[0].id
  start_ip_address     = "0.0.0.0"
  end_ip_address       = "0.0.0.0"
}

resource time_sleep synapse_workspace_rbac {
  count           = var.data.analytics.synapse.enable ? 1 : 0
  create_duration = "30s"
  depends_on = [
    azurerm_synapse_firewall_rule.allow_admin,
    azurerm_synapse_firewall_rule.allow_azure
  ]
}

resource azurerm_synapse_linked_service cosmos_db {
  count                = var.data.analytics.synapse.enable ? 1 : 0
  name                 = var.data.analytics.workspace.name
  synapse_workspace_id = azurerm_synapse_workspace.studio[0].id
  type                 = "CosmosDb"
  type_properties_json = jsonencode({
    connectionString = "${azurerm_cosmosdb_account.studio["sql"].primary_readonly_sql_connection_string}Database=${var.noSQL.databases[0].name}"
  })
  depends_on = [
    time_sleep.synapse_workspace_rbac
  ]
}

resource azurerm_synapse_sql_pool studio {
  for_each = {
    for sqlPool in var.data.analytics.synapse.sqlPools : sqlPool.name => sqlPool if var.data.analytics.synapse.enable && sqlPool.enable
  }
  name                 = each.value.name
  synapse_workspace_id = azurerm_synapse_workspace.studio[0].id
  sku_name             = each.value.size
}

resource azurerm_synapse_spark_pool studio {
  for_each = {
    for sparkPool in var.data.analytics.synapse.sparkPools : sparkPool.name => sparkPool if var.data.analytics.synapse.enable && sparkPool.enable
  }
  name                 = each.value.name
  synapse_workspace_id = azurerm_synapse_workspace.studio[0].id
  spark_version        = each.value.version
  node_size            = each.value.node.size
  node_size_family     = each.value.node.sizeFamily
  cache_size           = each.value.cache.sizePercent > 0 ? each.value.cache.sizePercent : null
  auto_scale {
    min_node_count = each.value.autoScale.nodeCountMin
    max_node_count = each.value.autoScale.nodeCountMax
  }
  auto_pause {
    delay_in_minutes = each.value.autoPause.idleMinutes
  }
}

resource azurerm_private_dns_zone synapse {
  count               = var.data.analytics.synapse.enable ? 1 : 0
  name                = "privatelink.sql.azuresynapse.net"
  resource_group_name = azurerm_resource_group.data_analytics_synapse[0].name
}

resource azurerm_private_dns_zone_virtual_network_link synapse {
  count                 = var.data.analytics.synapse.enable ? 1 : 0
  name                  = "synapse"
  resource_group_name   = azurerm_private_dns_zone.synapse[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.synapse[0].name
  virtual_network_id    = data.azurerm_virtual_network.studio_region.id
}

resource azurerm_private_endpoint synapse {
  count               = var.data.analytics.synapse.enable ? 1 : 0
  name                = "${azurerm_synapse_workspace.studio[0].name}-sql"
  resource_group_name = azurerm_resource_group.data_analytics_synapse[0].name
  location            = azurerm_resource_group.data_analytics_synapse[0].location
  subnet_id           = data.azurerm_subnet.data.id
  private_service_connection {
    name                           = azurerm_synapse_workspace.studio[0].name
    private_connection_resource_id = azurerm_synapse_workspace.studio[0].id
    is_manual_connection           = false
    subresource_names = [
      "Sql"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.synapse[0].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.synapse[0].id
    ]
  }
}
