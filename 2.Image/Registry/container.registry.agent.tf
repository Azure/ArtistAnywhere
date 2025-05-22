####################################################################################################
# Container Registry Agent (https://learn.microsoft.com/azure/container-registry/tasks-agent-pools #
####################################################################################################

resource azurerm_container_registry_agent_pool main {
  for_each = {
    for agentPool in var.containerRegistry.agentPools : agentPool.name => agentPool if agentPool.enable
  }
  name                      = each.value.name
  resource_group_name       = azurerm_resource_group.image_registry.name
  location                  = azurerm_resource_group.image_registry.location
  container_registry_name   = azurerm_container_registry.main.name
  virtual_network_subnet_id = data.azurerm_subnet.main.id
  tier                      = each.value.type
  instance_count            = each.value.count
}
