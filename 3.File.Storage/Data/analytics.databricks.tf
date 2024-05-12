##########################################################################
# Databricks (https://learn.microsoft.com/azure/databricks/introduction) #
##########################################################################

resource azurerm_resource_group data_analytics_databricks {
  count    = var.data.analytics.databricks.enable ? 1 : 0
  name     = "${azurerm_resource_group.data.name}Analytics.Databricks"
  location = azurerm_resource_group.data.location
}

resource azurerm_databricks_workspace studio {
  count                       = var.data.analytics.databricks.enable ? 1 : 0
  name                        = var.data.analytics.workspace.name
  resource_group_name         = azurerm_resource_group.data_analytics_databricks[0].name
  location                    = azurerm_resource_group.data_analytics_databricks[0].location
  sku                         = var.data.analytics.databricks.workspace.tier
  managed_resource_group_name = "${azurerm_resource_group.data_analytics_databricks[0].name}.Managed"
  custom_parameters {
    no_public_ip                  = true
    virtual_network_id            = !var.data.analytics.databricks.serverless.enable ? data.azurerm_virtual_network.studio_region.id : null
    vnet_address_prefix           = !var.data.analytics.databricks.serverless.enable ? data.azurerm_virtual_network.studio_region.address_space[0] : null
    private_subnet_name           = !var.data.analytics.databricks.serverless.enable ? data.azurerm_subnet.data.name : null
    # machine_learning_workspace_id = module.global.ai.machineLearning.enable ? data.azurerm_machine_learning_workspace.studio.id : null
  }
}

resource azurerm_databricks_virtual_network_peering studio {
  count                         = var.data.analytics.databricks.enable && var.data.analytics.databricks.serverless.enable ? 1 : 0
  name                          = data.azurerm_virtual_network.studio_region.name
  resource_group_name           = azurerm_resource_group.data_analytics_databricks[0].name
  workspace_id                  = azurerm_databricks_workspace.studio[0].id
  remote_virtual_network_id     = data.azurerm_virtual_network.studio_region.id
  remote_address_space_prefixes = data.azurerm_virtual_network.studio_region.address_space
}

resource azurerm_databricks_workspace_root_dbfs_customer_managed_key studio {
  count            = var.data.analytics.databricks.enable && var.data.analytics.workspace.encryption.enable ? 1 : 0
  workspace_id     = azurerm_databricks_workspace.studio[0].id
  key_vault_key_id = data.azurerm_key_vault_key.data_encryption[0].id
}

resource azurerm_private_dns_zone databricks {
  count               = var.data.analytics.databricks.enable && !var.data.analytics.databricks.serverless.enable ? 1 : 0
  name                = "privatelink.databricks.azure.us"
  resource_group_name = azurerm_resource_group.data_analytics_databricks[0].name
}

resource azurerm_private_dns_zone_virtual_network_link databricks {
  count                 = var.data.analytics.databricks.enable && !var.data.analytics.databricks.serverless.enable ? 1 : 0
  name                  = "databricks"
  resource_group_name   = azurerm_private_dns_zone.databricks[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.databricks[0].name
  virtual_network_id    = data.azurerm_virtual_network.studio_region.id
}
