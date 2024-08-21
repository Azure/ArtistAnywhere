####################################################################################
# AI Services (https://learn.microsoft.com/azure/ai-services/what-are-ai-services) #
####################################################################################

variable aiServices {
  type = object({
    enable = bool
    name   = string
    tier   = string
    domain = object({
      name = string
      fqdn = list(string)
    })
    localAuth = object({
      enable = bool
    })
    encryption = object({
      enable = bool
    })
  })
}

resource azurerm_ai_services studio {
  count                        = var.aiServices.enable ? 1 : 0
  name                         = var.aiServices.name
  resource_group_name          = azurerm_resource_group.studio_ai[0].name
  location                     = azurerm_resource_group.studio_ai[0].location
  sku_name                     = var.aiServices.tier
  custom_subdomain_name        = var.aiServices.domain.name != "" ? var.aiServices.domain.name : var.aiServices.name
  fqdns                        = length(var.aiServices.domain.fqdn) > 0 ? var.aiServices.domain.fqdn : null
  local_authentication_enabled = var.aiServices.localAuth.enable
  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.studio.id
    ]
  }
  network_acls {
    default_action = "Deny"
    ip_rules = [
      jsondecode(data.http.client_address.response_body).ip
    ]
  }
  storage {
    storage_account_id = azurerm_storage_account.studio.id
    identity_client_id = azurerm_user_assigned_identity.studio.client_id
  }
  dynamic customer_managed_key {
    for_each = var.aiServices.encryption.enable ? [1] : []
    content {
      key_vault_key_id   = azurerm_key_vault_key.data_encryption.id
      identity_client_id = azurerm_user_assigned_identity.studio.client_id
    }
  }
}

###################################################################################################
# AI Video Indexer (https://learn.microsoft.com/azure/azure-video-indexer/video-indexer-overview) #
###################################################################################################

resource azurerm_role_assignment ai_video_indexer_storage_blob_data_owner {
  count                = var.aiServices.enable ? 1 : 0
  role_definition_name = "Storage Blob Data Owner" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/storage#storage-blob-data-owner
  principal_id         = azurerm_user_assigned_identity.studio.principal_id
  scope                = azurerm_storage_account.studio.id
}

resource azurerm_role_assignment ai_video_indexer_cognitive_services_user {
  count                = var.aiServices.enable ? 1 : 0
  role_definition_name = "Cognitive Services User" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/ai-machine-learning#cognitive-services-user
  principal_id         = azurerm_user_assigned_identity.studio.principal_id
  scope                = azurerm_ai_services.studio[0].id
}

resource azurerm_role_assignment ai_video_indexer_cognitive_services_contributor {
  count                = var.aiServices.enable ? 1 : 0
  role_definition_name = "Cognitive Services Contributor" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/ai-machine-learning#cognitive-services-contributor
  principal_id         = azurerm_user_assigned_identity.studio.principal_id
  scope                = azurerm_ai_services.studio[0].id
}

resource azapi_resource ai_video_indexer {
  count     = var.aiServices.enable ? 1 : 0
  name      = var.aiServices.name
  type      = "Microsoft.VideoIndexer/accounts@2024-06-01-preview"
  parent_id = azurerm_resource_group.studio_ai[0].id
  location  = azurerm_resource_group.studio_ai[0].location
  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.studio.id
    ]
  }
  body = jsonencode({
    properties = {
      storageServices = {
        resourceId           = azurerm_storage_account.studio.id
        userAssignedIdentity = azurerm_user_assigned_identity.studio.id
      }
      openAiServices = {
        resourceId           = azurerm_ai_services.studio[0].id
        userAssignedIdentity = azurerm_user_assigned_identity.studio.id
      }
    }
  })
  depends_on = [
    azurerm_role_assignment.ai_video_indexer_storage_blob_data_owner,
    azurerm_role_assignment.ai_video_indexer_cognitive_services_user,
    azurerm_role_assignment.ai_video_indexer_cognitive_services_contributor
  ]
}

####################################################################################
# AI Search (https://learn.microsoft.com/azure/search/search-what-is-azure-search) #
####################################################################################

variable aiSearch {
  type = object({
    enable         = bool
    name           = string
    tier           = string
    hostingMode    = string
    replicaCount   = number
    partitionCount = number
    localAuth = object({
      enable = bool
    })
    sharedPrivateAccess = object({
      enable = bool
    })
  })
}

resource azurerm_search_service studio {
  count                        = var.aiSearch.enable ? 1 : 0
  name                         = var.aiSearch.name
  resource_group_name          = azurerm_resource_group.studio_ai[0].name
  location                     = azurerm_resource_group.studio_ai[0].location
  sku                          = var.aiSearch.tier
  hosting_mode                 = var.aiSearch.hostingMode
  replica_count                = var.aiSearch.replicaCount
  partition_count              = var.aiSearch.partitionCount
  local_authentication_enabled = var.aiSearch.localAuth.enable
  # identity {
  #   type = "UserAssigned"
  #   identity_ids = [
  #     data.azurerm_user_assigned_identity.studio.id
  #   ]
  # }
  allowed_ips = [
    jsondecode(data.http.client_address.response_body).ip
  ]
}

resource azurerm_search_shared_private_link_service studio {
  count              = var.aiSearch.enable && var.aiSearch.sharedPrivateAccess.enable ? 1 : 0
  name               = azurerm_search_service.studio[0].name
  search_service_id  = azurerm_search_service.studio[0].id
  target_resource_id = azurerm_storage_account.studio.id
  subresource_name   = "blob"
}

#################################################################################################################
# Machine Learning (https://learn.microsoft.com/azure/machine-learning/overview-what-is-azure-machine-learning) #
#################################################################################################################

variable aiMachineLearning {
  type = object({
    enable = bool
    workspace = object({
      name = string
      type = string
      tier = string
    })
  })
}

resource azurerm_machine_learning_workspace studio {
  count                          = var.aiMachineLearning.enable ? 1 : 0
  name                           = var.aiMachineLearning.workspace.name
  resource_group_name            = azurerm_resource_group.studio_ai[0].name
  location                       = azurerm_resource_group.studio_ai[0].location
  kind                           = var.aiMachineLearning.workspace.type
  sku_name                       = var.aiMachineLearning.workspace.tier
  key_vault_id                   = azurerm_key_vault.studio.id
  storage_account_id             = azurerm_storage_account.studio.id
  primary_user_assigned_identity = azurerm_user_assigned_identity.studio.id
  application_insights_id        = azurerm_application_insights.studio.id
  container_registry_id          = var.containerRegistry.enable ? azurerm_container_registry.studio[0].id : null
  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.studio.id
    ]
  }
}

output ai {
  value = {
    enable            = local.aiEnable
    regionName        = local.aiEnable ? azurerm_resource_group.studio_ai[0].location : null
    resourceGroupName = local.aiEnable ? azurerm_resource_group.studio_ai[0].name : null
    services = {
      enable = var.aiServices.enable
      id     = var.aiServices.enable ? azurerm_ai_services.studio[0].id : null
      name   = var.aiServices.enable ? azurerm_ai_services.studio[0].name : null
      videoIndexer = {
        id     = var.aiServices.enable ? azapi_resource.ai_video_indexer[0].id : null
        name   = var.aiServices.enable ? azapi_resource.ai_video_indexer[0].name : null
      }
    }
    search = {
      enable = var.aiSearch.enable
      id     = var.aiSearch.enable ? azurerm_search_service.studio[0].id : null
      name   = var.aiSearch.enable ? azurerm_search_service.studio[0].name : null
    }
    machineLearning = {
      enable = var.aiMachineLearning.enable
      workspace = {
        id   = var.aiMachineLearning.enable ? azurerm_machine_learning_workspace.studio[0].id : null
        name = var.aiMachineLearning.enable ? azurerm_machine_learning_workspace.studio[0].name : null
      }
    }
  }
}
