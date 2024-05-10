#######################################################################################################
# Stream Analytics (https://learn.microsoft.com/azure/stream-analytics/stream-analytics-introduction) #
#######################################################################################################

resource azurerm_resource_group data_analytics_stream {
  count    = var.data.analytics.stream.enable ? 1 : 0
  name     = "${azurerm_resource_group.data.name}Analytics.Stream"
  location = azurerm_resource_group.data.location
}

resource azurerm_stream_analytics_cluster studio {
  count               = var.data.analytics.stream.enable ? 1 : 0
  name                = var.data.analytics.stream.cluster.name
  resource_group_name = azurerm_resource_group.data_analytics_stream[0].name
  location            = azurerm_resource_group.data_analytics_stream[0].location
  streaming_capacity  = var.data.analytics.stream.cluster.size
}
