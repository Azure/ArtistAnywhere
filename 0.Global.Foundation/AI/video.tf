###################################################################################################
# AI Video Indexer (https://learn.microsoft.com/azure/azure-video-indexer/video-indexer-overview) #
###################################################################################################

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
}
