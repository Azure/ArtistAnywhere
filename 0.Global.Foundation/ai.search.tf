#################################################################################
# Search (https://learn.microsoft.com/azure/search/search-what-is-azure-search) #
#################################################################################

resource azurerm_search_service studio {
  count               = var.ai.search.enable && module.global.ai.enable ? 1 : 0
  name                = var.ai.search.name
  resource_group_name = azurerm_resource_group.studio_ai[0].name
  location            = azurerm_resource_group.studio_ai[0].location
  sku                 = var.ai.search.tier
  hosting_mode        = var.ai.search.hostingMode
  replica_count       = var.ai.search.replicaCount
  partition_count     = var.ai.search.partitionCount
  # identity {
  #   type = "UserAssigned"
  #   identity_ids = [
  #     azurerm_user_assigned_identity.studio.id
  #   ]
  # }
  allowed_ips = [
    jsondecode(data.http.client_address.response_body).ip
  ]
}

resource azurerm_search_shared_private_link_service studio {
  count              = var.ai.search.enable && var.ai.search.sharedPrivateAccess.enable && module.global.ai.enable ? 1 : 0
  name               = azurerm_search_service.studio[0].name
  search_service_id  = azurerm_search_service.studio[0].id
  target_resource_id = azurerm_storage_account.studio.id
  subresource_name   = "blob"
}
