####################################################################################################################
# Container Registry Task (https://learn.microsoft.com/azure/container-registry/container-registry-tasks-overview) #
####################################################################################################################

resource azurerm_container_registry_task studio {
  for_each = {
    for task in var.containerRegistry.tasks : task.name => task if task.enable
  }
  name                  = each.value.name
  container_registry_id = azurerm_container_registry.studio.id
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  platform {
    os = each.value.type
  }
  docker_step {
    context_path         = each.value.docker.context.hostUrl
    context_access_token = each.value.docker.context.accessToken
    dockerfile_path      = each.value.docker.filePath
    image_names          = each.value.docker.imageNames
    cache_enabled        = each.value.docker.cache.enable
  }
  agent_pool_name    = each.value.agentPool.enable ? each.value.agentPool.name : null
  timeout_in_seconds = each.value.timeout.seconds
  depends_on = [
    azurerm_container_registry_agent_pool.studio
  ]
}
