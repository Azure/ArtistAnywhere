#################################################################################
# Search (https://learn.microsoft.com/azure/search/search-what-is-azure-search) #
#################################################################################

variable search {
  type = object({
    tier           = string
    hostingMode    = string
    replicaCount   = number
    partitionCount = number
    sharedPrivateAccess = object({
      enable = bool
    })
  })
}

resource azurerm_search_service studio {
  count                        = module.global.search.enable ? 1 : 0
  name                         = module.global.search.name
  resource_group_name          = azurerm_resource_group.studio.name
  location                     = azurerm_resource_group.studio.location
  sku                          = var.search.tier
  hosting_mode                 = var.search.hostingMode
  replica_count                = var.search.replicaCount
  partition_count              = var.search.partitionCount
  local_authentication_enabled = false
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
  count              = module.global.search.enable && var.search.sharedPrivateAccess.enable ? 1 : 0
  name               = azurerm_search_service.studio[0].name
  search_service_id  = azurerm_search_service.studio[0].id
  target_resource_id = azurerm_storage_account.studio.id
  subresource_name   = "blob"
}
