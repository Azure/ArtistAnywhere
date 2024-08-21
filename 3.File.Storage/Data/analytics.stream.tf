#######################################################################################################
# Stream Analytics (https://learn.microsoft.com/azure/stream-analytics/stream-analytics-introduction) #
#######################################################################################################

resource azurerm_resource_group data_analytics_stream {
  count    = var.data.analytics.stream.enable ? 1 : 0
  name     = "${azurerm_resource_group.data.name}Analytics.Stream"
  location = azurerm_resource_group.data.location
}

resource azapi_resource stream_analytics_cluster {
  count     = var.data.analytics.stream.enable ? 1 : 0
  name      = var.data.analytics.stream.cluster.name
  type      = "Microsoft.StreamAnalytics/clusters@2020-03-01"
  parent_id = azurerm_resource_group.data_analytics_stream[0].id
  location  = azurerm_resource_group.data_analytics_stream[0].location
  body = jsonencode({
    sku = {
      name     = "DefaultV2"
      capacity = var.data.analytics.stream.cluster.size
    }
  })
  timeouts {
    create = "60m"
  }
}

resource azurerm_stream_analytics_managed_private_endpoint event_hub {
  count                         = var.data.analytics.stream.enable ? 1 : 0
  name                          = "${azapi_resource.stream_analytics_cluster[0].name}-namespace"
  resource_group_name           = azurerm_resource_group.data_analytics_stream[0].name
  stream_analytics_cluster_name = azapi_resource.stream_analytics_cluster[0].name
  target_resource_id            = azurerm_eventhub_namespace.data[0].id
  subresource_name              = "namespace"
}

resource azurerm_stream_analytics_managed_private_endpoint storage {
  count                         = var.data.analytics.stream.enable ? 1 : 0
  name                          = "${azurerm_storage_account.datalake.name}-blob"
  resource_group_name           = azurerm_resource_group.data_analytics_stream[0].name
  stream_analytics_cluster_name = azapi_resource.stream_analytics_cluster[0].name
  target_resource_id            = azurerm_storage_account.datalake.id
  subresource_name              = "blob"
}

resource azurerm_stream_analytics_managed_private_endpoint cosmos_sql {
  count                         = var.data.analytics.stream.enable ? 1 : 0
  name                          = "${azapi_resource.stream_analytics_cluster[0].name}-sql"
  resource_group_name           = azurerm_resource_group.data_analytics_stream[0].name
  stream_analytics_cluster_name = azapi_resource.stream_analytics_cluster[0].name
  target_resource_id            = azurerm_cosmosdb_account.studio["sql"].id
  subresource_name              = "Sql"
}
