####################################################################################################################
# Container Registry Task (https://learn.microsoft.com/azure/container-registry/container-registry-tasks-overview) #
####################################################################################################################

variable containerRegistryTasks {
  type = list(object({
    enable = bool
    name   = string
    type   = string
    docker = object({
      context = object({
        hostUrl     = string
        accessToken = string
      })
      filePath    = string
      imageNames  = list(string)
      cache = object({
        enable = bool
      })
    })
  }))
}

resource azurerm_container_registry_task studio {
  for_each = {
    for task in var.containerRegistryTasks : task.name => task if task.enable
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
}
