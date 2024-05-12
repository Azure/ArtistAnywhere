###################################################################################################
# AI Video Indexer (https://learn.microsoft.com/azure/azure-video-indexer/video-indexer-overview) #
###################################################################################################

resource azurerm_role_assignment video_indexer {
  count                = var.ai.video.enable && module.global.ai.enable ? 1 : 0
  role_definition_name = "Storage Blob Data Contributor" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#storage_blob_data_contributor
  principal_id         = azurerm_user_assigned_identity.studio.principal_id
  scope                = azurerm_storage_account.studio.id
}

resource time_sleep video_indexer_rbac {
  count           = var.ai.video.enable && module.global.ai.enable ? 1 : 0
  create_duration = "30s"
  depends_on = [
    azurerm_role_assignment.video_indexer
  ]
}

resource azapi_resource ai_video_indexer {
  count     = var.ai.video.enable && module.global.ai.enable ? 1 : 0
  name      = var.ai.video.name
  type      = "Microsoft.VideoIndexer/accounts@2024-04-01-preview"
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
    }
  })
  depends_on = [
    time_sleep.video_indexer_rbac
  ]
}
