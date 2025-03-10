###############################################################################################
# Compute Gallery (https://learn.microsoft.com/azure/virtual-machines/shared-image-galleries) #
###############################################################################################

variable computeGallery {
  type = object({
    name = string
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

locals {
  imageDefinitionLinux = [
    for imageDefinition in var.computeGallery.imageDefinitions : imageDefinition if lower(imageDefinition.type) == "linux"
  ]
}

resource azurerm_shared_image_gallery studio {
  name                = var.computeGallery.name
  resource_group_name = azurerm_resource_group.image_gallery.name
  location            = azurerm_resource_group.image_gallery.location
}

resource azurerm_shared_image studio {
  for_each = {
    for imageDefinition in var.computeGallery.imageDefinitions : imageDefinition.name => imageDefinition if (module.core.image.linux.enable && lower(imageDefinition.type) == "linux") || (module.core.image.windows.enable && lower(imageDefinition.type) == "windows")
  }
  name                = each.value.name
  resource_group_name = azurerm_resource_group.image_gallery.name
  location            = azurerm_resource_group.image_gallery.location
  gallery_name        = azurerm_shared_image_gallery.studio.name
  hyper_v_generation  = each.value.generation
  os_type             = each.value.type
  identifier {
    publisher = each.value.publisher
    offer     = each.value.offer
    sku       = each.value.sku
  }
}

output linux {
  value = !module.core.image.linux.enable || length(local.imageDefinitionLinux) == 0 ? null : {
    publisher = lower(local.imageDefinitionLinux[0].publisher)
    offer     = lower(local.imageDefinitionLinux[0].offer)
    sku       = lower(local.imageDefinitionLinux[0].sku)
    version   = module.core.image.linux.version
  }
}
