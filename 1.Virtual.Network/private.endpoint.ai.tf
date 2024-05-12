
resource azurerm_private_dns_zone ai {
  count               = module.global.ai.enable ? 1 : 0
  name                = "privatelink.cognitiveservices.azure.com"
  resource_group_name = azurerm_resource_group.network.name
}

resource azurerm_private_dns_zone ai_open {
  count               = module.global.ai.enable ? 1 : 0
  name                = "privatelink.openai.azure.com"
  resource_group_name = azurerm_resource_group.network.name
}

resource azurerm_private_dns_zone ai_search {
  count               = module.global.ai.enable ? 1 : 0
  name                = "privatelink.search.windows.net"
  resource_group_name = azurerm_resource_group.network.name
}

resource azurerm_private_dns_zone_virtual_network_link ai {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.key => virtualNetwork if module.global.ai.enable
  }
  name                  = "${lower(each.value.key)}-ai"
  resource_group_name   = azurerm_private_dns_zone.ai[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.ai[0].name
  virtual_network_id    = each.value.id
}

resource azurerm_private_dns_zone_virtual_network_link ai_open {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.key => virtualNetwork if module.global.ai.enable
  }
  name                  = "${lower(each.value.key)}-ai-open"
  resource_group_name   = azurerm_private_dns_zone.ai_open[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.ai_open[0].name
  virtual_network_id    = each.value.id
}

resource azurerm_private_dns_zone_virtual_network_link ai_search {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.key => virtualNetwork if module.global.ai.enable
  }
  name                  = "${lower(each.value.key)}-ai-search"
  resource_group_name   = azurerm_private_dns_zone.ai_search[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.ai_search[0].name
  virtual_network_id    = each.value.id
}

# resource azurerm_private_endpoint ai {
#   for_each = {
#     for subnet in local.virtualNetworksSubnetCompute : subnet.key => subnet if module.global.ai.enable && subnet.virtualNetworkEdgeZone == ""
#   }
#   name                = "${lower(each.value.virtualNetworkKey)}-ai"
#   resource_group_name = each.value.resourceGroupName
#   location            = each.value.regionName
#   subnet_id           = "${each.value.virtualNetworkId}/subnets/${each.value.name}"
#   private_service_connection {
#     name                           = azurerm_cognitive_account.ai[0].name
#     private_connection_resource_id = azurerm_cognitive_account.ai[0].id
#     is_manual_connection           = false
#     subresource_names = [
#       "account"
#     ]
#   }
#   private_dns_zone_group {
#     name = azurerm_private_dns_zone_virtual_network_link.ai[each.value.virtualNetworkKey].name
#     private_dns_zone_ids = [
#       azurerm_private_dns_zone.ai[0].id
#     ]
#   }
# }

# resource azurerm_private_endpoint ai_open {
#   for_each = {
#     for subnet in local.virtualNetworksSubnetCompute : subnet.key => subnet if module.global.ai.enable && subnet.virtualNetworkEdgeZone == ""
#   }
#   name                = "${lower(each.value.virtualNetworkKey)}-ai-open"
#   resource_group_name = each.value.resourceGroupName
#   location            = each.value.regionName
#   subnet_id           = "${each.value.virtualNetworkId}/subnets/${each.value.name}"
#   private_service_connection {
#     name                           = azurerm_cognitive_account.ai_open[0].name
#     private_connection_resource_id = azurerm_cognitive_account.ai_open[0].id
#     is_manual_connection           = false
#     subresource_names = [
#       "account"
#     ]
#   }
#   private_dns_zone_group {
#     name = azurerm_private_dns_zone_virtual_network_link.ai_open[each.value.virtualNetworkKey].name
#     private_dns_zone_ids = [
#       azurerm_private_dns_zone.ai_open[0].id
#     ]
#   }
# }

# resource azurerm_private_endpoint ai_vision {
#   for_each = {
#     for subnet in local.virtualNetworksSubnetCompute : subnet.key => subnet if module.global.ai.enable && subnet.virtualNetworkEdgeZone == ""
#   }
#   name                = "${lower(each.value.virtualNetworkKey)}-ai-vision"
#   resource_group_name = each.value.resourceGroupName
#   location            = each.value.regionName
#   subnet_id           = "${each.value.virtualNetworkId}/subnets/${each.value.name}"
#   private_service_connection {
#     name                           = azurerm_cognitive_account.ai_vision[0].name
#     private_connection_resource_id = azurerm_cognitive_account.ai_vision[0].id
#     is_manual_connection           = false
#     subresource_names = [
#       "account"
#     ]
#   }
#   private_dns_zone_group {
#     name = azurerm_private_dns_zone_virtual_network_link.ai[each.value.virtualNetworkKey].name
#     private_dns_zone_ids = [
#       azurerm_private_dns_zone.ai[0].id
#     ]
#   }
# }

# resource azurerm_private_endpoint ai_vision_training {
#   for_each = {
#     for subnet in local.virtualNetworksSubnetCompute : subnet.key => subnet if module.global.ai.enable && subnet.virtualNetworkEdgeZone == ""
#   }
#   name                = "${lower(each.value.virtualNetworkKey)}-ai-vision-training"
#   resource_group_name = each.value.resourceGroupName
#   location            = each.value.regionName
#   subnet_id           = "${each.value.virtualNetworkId}/subnets/${each.value.name}"
#   private_service_connection {
#     name                           = azurerm_cognitive_account.ai_vision_training[0].name
#     private_connection_resource_id = azurerm_cognitive_account.ai_vision_training[0].id
#     is_manual_connection           = false
#     subresource_names = [
#       "account"
#     ]
#   }
#   private_dns_zone_group {
#     name = azurerm_private_dns_zone_virtual_network_link.ai[each.value.virtualNetworkKey].name
#     private_dns_zone_ids = [
#       azurerm_private_dns_zone.ai[0].id
#     ]
#   }
# }

# resource azurerm_private_endpoint ai_vision_prediction {
#   for_each = {
#     for subnet in local.virtualNetworksSubnetCompute : subnet.key => subnet if module.global.ai.enable && subnet.virtualNetworkEdgeZone == ""
#   }
#   name                = "${lower(each.value.virtualNetworkKey)}-ai-vision-prediction"
#   resource_group_name = each.value.resourceGroupName
#   location            = each.value.regionName
#   subnet_id           = "${each.value.virtualNetworkId}/subnets/${each.value.name}"
#   private_service_connection {
#     name                           = azurerm_cognitive_account.ai_vision_prediction[0].name
#     private_connection_resource_id = azurerm_cognitive_account.ai_vision_prediction[0].id
#     is_manual_connection           = false
#     subresource_names = [
#       "account"
#     ]
#   }
#   private_dns_zone_group {
#     name = azurerm_private_dns_zone_virtual_network_link.ai[each.value.virtualNetworkKey].name
#     private_dns_zone_ids = [
#       azurerm_private_dns_zone.ai[0].id
#     ]
#   }
# }

# resource azurerm_private_endpoint ai_face {
#   for_each = {
#     for subnet in local.virtualNetworksSubnetCompute : subnet.key => subnet if module.global.ai.enable && subnet.virtualNetworkEdgeZone == ""
#   }
#   name                = "${lower(each.value.virtualNetworkKey)}-ai-face"
#   resource_group_name = each.value.resourceGroupName
#   location            = each.value.regionName
#   subnet_id           = "${each.value.virtualNetworkId}/subnets/${each.value.name}"
#   private_service_connection {
#     name                           = azurerm_cognitive_account.ai_face[0].name
#     private_connection_resource_id = azurerm_cognitive_account.ai_face[0].id
#     is_manual_connection           = false
#     subresource_names = [
#       "account"
#     ]
#   }
#   private_dns_zone_group {
#     name = azurerm_private_dns_zone_virtual_network_link.ai[each.value.virtualNetworkKey].name
#     private_dns_zone_ids = [
#       azurerm_private_dns_zone.ai[0].id
#     ]
#   }
# }

# resource azurerm_private_endpoint ai_speech {
#   for_each = {
#     for subnet in local.virtualNetworksSubnetCompute : subnet.key => subnet if module.global.ai.enable && subnet.virtualNetworkEdgeZone == ""
#   }
#   name                = "${lower(each.value.virtualNetworkKey)}-ai-speech"
#   resource_group_name = each.value.resourceGroupName
#   location            = each.value.regionName
#   subnet_id           = "${each.value.virtualNetworkId}/subnets/${each.value.name}"
#   private_service_connection {
#     name                           = azurerm_cognitive_account.ai_speech[0].name
#     private_connection_resource_id = azurerm_cognitive_account.ai_speech[0].id
#     is_manual_connection           = false
#     subresource_names = [
#       "account"
#     ]
#   }
#   private_dns_zone_group {
#     name = azurerm_private_dns_zone_virtual_network_link.ai[each.value.virtualNetworkKey].name
#     private_dns_zone_ids = [
#       azurerm_private_dns_zone.ai[0].id
#     ]
#   }
# }

# resource azurerm_private_endpoint ai_language_conversational {
#   for_each = {
#     for subnet in local.virtualNetworksSubnetCompute : subnet.key => subnet if module.global.ai.enable && subnet.virtualNetworkEdgeZone == ""
#   }
#   name                = "${lower(each.value.virtualNetworkKey)}-ai-language-conversational"
#   resource_group_name = each.value.resourceGroupName
#   location            = each.value.regionName
#   subnet_id           = "${each.value.virtualNetworkId}/subnets/${each.value.name}"
#   private_service_connection {
#     name                           = azurerm_cognitive_account.ai_language_conversational[0].name
#     private_connection_resource_id = azurerm_cognitive_account.ai_language_conversational[0].id
#     is_manual_connection           = false
#     subresource_names = [
#       "account"
#     ]
#   }
#   private_dns_zone_group {
#     name = azurerm_private_dns_zone_virtual_network_link.ai[each.value.virtualNetworkKey].name
#     private_dns_zone_ids = [
#       azurerm_private_dns_zone.ai[0].id
#     ]
#   }
# }

# resource azurerm_private_endpoint ai_text_analytics {
#   for_each = {
#     for subnet in local.virtualNetworksSubnetCompute : subnet.key => subnet if module.global.ai.enable && subnet.virtualNetworkEdgeZone == ""
#   }
#   name                = "${lower(each.value.virtualNetworkKey)}-ai-text-analytics"
#   resource_group_name = each.value.resourceGroupName
#   location            = each.value.regionName
#   subnet_id           = "${each.value.virtualNetworkId}/subnets/${each.value.name}"
#   private_service_connection {
#     name                           = azurerm_cognitive_account.ai_text_analytics[0].name
#     private_connection_resource_id = azurerm_cognitive_account.ai_text_analytics[0].id
#     is_manual_connection           = false
#     subresource_names = [
#       "account"
#     ]
#   }
#   private_dns_zone_group {
#     name = azurerm_private_dns_zone_virtual_network_link.ai[each.value.virtualNetworkKey].name
#     private_dns_zone_ids = [
#       azurerm_private_dns_zone.ai[0].id
#     ]
#   }
# }

# resource azurerm_private_endpoint ai_text_translation {
#   for_each = {
#     for subnet in local.virtualNetworksSubnetCompute : subnet.key => subnet if module.global.ai.enable && subnet.virtualNetworkEdgeZone == ""
#   }
#   name                = "${lower(each.value.virtualNetworkKey)}-ai-text-translation"
#   resource_group_name = each.value.resourceGroupName
#   location            = each.value.regionName
#   subnet_id           = "${each.value.virtualNetworkId}/subnets/${each.value.name}"
#   private_service_connection {
#     name                           = azurerm_cognitive_account.ai_text_translation[0].name
#     private_connection_resource_id = azurerm_cognitive_account.ai_text_translation[0].id
#     is_manual_connection           = false
#     subresource_names = [
#       "account"
#     ]
#   }
#   private_dns_zone_group {
#     name = azurerm_private_dns_zone_virtual_network_link.ai[each.value.virtualNetworkKey].name
#     private_dns_zone_ids = [
#       azurerm_private_dns_zone.ai[0].id
#     ]
#   }
# }

# resource azurerm_private_endpoint ai_document {
#   for_each = {
#     for subnet in local.virtualNetworksSubnetCompute : subnet.key => subnet if module.global.ai.enable && subnet.virtualNetworkEdgeZone == ""
#   }
#   name                = "${lower(each.value.virtualNetworkKey)}-ai-document"
#   resource_group_name = each.value.resourceGroupName
#   location            = each.value.regionName
#   subnet_id           = "${each.value.virtualNetworkId}/subnets/${each.value.name}"
#   private_service_connection {
#     name                           = azurerm_cognitive_account.ai_document[0].name
#     private_connection_resource_id = azurerm_cognitive_account.ai_document[0].id
#     is_manual_connection           = false
#     subresource_names = [
#       "account"
#     ]
#   }
#   private_dns_zone_group {
#     name = azurerm_private_dns_zone_virtual_network_link.ai[each.value.virtualNetworkKey].name
#     private_dns_zone_ids = [
#       azurerm_private_dns_zone.ai[0].id
#     ]
#   }
# }

# resource azurerm_private_endpoint search {
#   count               = module.global.ai.enable ? 1 : 0
#   name                = "${azurerm_search_service.studio[0].name}-${azurerm_private_dns_zone_virtual_network_link.search[0].name}"
#   resource_group_name = azurerm_search_service.studio[0].resource_group_name
#   location            = azurerm_search_service.studio[0].location
#   subnet_id           = data.azurerm_subnet.data.id
#   private_service_connection {
#     name                           = azurerm_search_service.studio[0].name
#     private_connection_resource_id = azurerm_search_service.studio[0].id
#     is_manual_connection           = false
#     subresource_names = [
#       "searchService"
#     ]
#   }
#   private_dns_zone_group {
#     name = azurerm_private_dns_zone_virtual_network_link.search[0].name
#     private_dns_zone_ids = [
#       azurerm_private_dns_zone.search[0].id
#     ]
#   }
# }
