###############################################################################################
# Compute Gallery (https://learn.microsoft.com/azure/virtual-machines/shared-image-galleries) #
###############################################################################################

variable computeGallery {
  type = object({
    name   = string
    enable = bool
    platform = object({
      linux = object({
        enable = bool
      })
      windows = object({
        enable = bool
      })
    })
    imageDefinitions = list(object({
      name       = string
      type       = string
      generation = string
      publisher  = string
      offer      = string
      sku        = string
    }))
  })
}

resource azurerm_shared_image_gallery studio {
  count               = var.computeGallery.enable ? 1 : 0
  name                = var.computeGallery.name
  resource_group_name = azurerm_resource_group.image.name
  location            = azurerm_resource_group.image.location
}

resource azurerm_shared_image linux {
  for_each = {
    for imageDefinition in var.computeGallery.imageDefinitions : imageDefinition.name => imageDefinition if imageDefinition.type == "Linux" && var.computeGallery.enable && var.computeGallery.platform.linux.enable
  }
  name                = each.value.name
  resource_group_name = azurerm_resource_group.image.name
  location            = azurerm_resource_group.image.location
  gallery_name        = azurerm_shared_image_gallery.studio[0].name
  hyper_v_generation  = each.value.generation
  os_type             = each.value.type
  identifier {
    publisher = each.value.publisher
    offer     = each.value.offer
    sku       = each.value.sku
  }
}

resource azurerm_shared_image windows {
  for_each = {
    for imageDefinition in var.computeGallery.imageDefinitions : imageDefinition.name => imageDefinition if imageDefinition.type == "Windows" && var.computeGallery.enable && var.computeGallery.platform.windows.enable
  }
  name                = each.value.name
  resource_group_name = azurerm_resource_group.image.name
  location            = azurerm_resource_group.image.location
  gallery_name        = azurerm_shared_image_gallery.studio[0].name
  hyper_v_generation  = each.value.generation
  os_type             = each.value.type
  identifier {
    publisher = each.value.publisher
    offer     = each.value.offer
    sku       = each.value.sku
  }
}
