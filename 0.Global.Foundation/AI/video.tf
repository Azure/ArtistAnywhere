###################################################################################################
# AI Video Indexer (https://learn.microsoft.com/azure/azure-video-indexer/video-indexer-overview) #
###################################################################################################

resource azurerm_role_assignment storage_blob_data_owner {
  count                = var.ai.video.enable ? 1 : 0
  role_definition_name = "Storage Blob Data Owner" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/storage#storage-blob-data-owner
  principal_id         = data.azurerm_user_assigned_identity.studio.principal_id
  scope                = data.azurerm_storage_account.studio.id
}

resource azurerm_role_assignment storage_blob_data_contributor {
  count                = var.ai.video.enable ? 1 : 0
  role_definition_name = "Storage Blob Data Contributor" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/storage#storage-blob-data-contributor
  principal_id         = data.azurerm_user_assigned_identity.studio.principal_id
  scope                = data.azurerm_storage_account.studio.id
}

resource time_sleep ai_video_indexer_rbac {
  count           = var.ai.video.enable ? 1 : 0
  create_duration = "30s"
  depends_on = [
    azurerm_role_assignment.storage_blob_data_owner,
    azurerm_role_assignment.storage_blob_data_contributor
  ]
}

resource azapi_resource ai_video_indexer {
  count     = var.ai.video.enable ? 1 : 0
  name      = var.ai.video.name
  type      = "Microsoft.VideoIndexer/accounts@2024-06-01-preview"
  parent_id = azurerm_resource_group.ai.id
  location  = azurerm_resource_group.ai.location
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  body = jsonencode({
    properties = {
      storageServices = {
        resourceId           = data.azurerm_storage_account.studio.id
        userAssignedIdentity = data.azurerm_user_assigned_identity.studio.id
      }
    }
  })
  depends_on = [
    time_sleep.ai_video_indexer_rbac
  ]
}
