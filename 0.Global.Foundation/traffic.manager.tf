################################################################################################
# Traffic Manager (https://learn.microsoft.com/azure/traffic-manager/traffic-manager-overview) #
################################################################################################

variable trafficManager {
  type = object({
    routingMethod = string
    dns = object({
      name = string
      ttl  = number
    })
    monitor = object({
      protocol = string
      port     = number
      path     = string
    })
    trafficView = object({
      enable = bool
    })
  })
}

resource azurerm_traffic_manager_profile studio {
  count                  = module.global.trafficManager.enable ? 1 : 0
  name                   = module.global.trafficManager.name
  resource_group_name    = azurerm_resource_group.studio.name
  traffic_routing_method = var.trafficManager.routingMethod
  traffic_view_enabled   = var.trafficManager.trafficView.enable
  dns_config {
    relative_name = var.trafficManager.dns.name
    ttl           = var.trafficManager.dns.ttl
  }
  monitor_config {
    protocol = var.trafficManager.monitor.protocol
    port     = var.trafficManager.monitor.port
    path     = var.trafficManager.monitor.path
  }
}
