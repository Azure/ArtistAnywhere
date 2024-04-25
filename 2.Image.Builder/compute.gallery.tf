###############################################################################################
# Compute Gallery (https://learn.microsoft.com/azure/virtual-machines/shared-image-galleries) #
###############################################################################################

variable computeGallery {
  type = object({
    name = string
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
    appDefinitions = list(object({
      name = string
      type = string
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
  resource_group_name = azurerm_resource_group.image.name
  location            = azurerm_resource_group.image.location
}

resource azurerm_shared_image studio {
  for_each = {
    for imageDefinition in var.computeGallery.imageDefinitions : imageDefinition.name => imageDefinition if (var.computeGallery.platform.linux.enable && lower(imageDefinition.type) == "linux") || (var.computeGallery.platform.windows.enable && lower(imageDefinition.type) == "windows")
  }
  name                = each.value.name
  resource_group_name = azurerm_resource_group.image.name
  location            = azurerm_resource_group.image.location
  gallery_name        = azurerm_shared_image_gallery.studio.name
  hyper_v_generation  = each.value.generation
  os_type             = each.value.type
  identifier {
    publisher = each.value.publisher
    offer     = each.value.offer
    sku       = each.value.sku
  }
}

resource azurerm_gallery_application studio {
  for_each = {
    for appDefinition in var.computeGallery.appDefinitions : appDefinition.name => appDefinition if (var.computeGallery.platform.linux.enable && lower(appDefinition.type) == "linux") || (var.computeGallery.platform.windows.enable && lower(appDefinition.type) == "windows")
  }
  name              = each.value.name
  location          = azurerm_resource_group.image.location
  gallery_id        = azurerm_shared_image_gallery.studio.id
  supported_os_type = each.value.type
}

output linuxPlan {
  value = !var.computeGallery.platform.linux.enable || length(local.imageDefinitionLinux) == 0 ? null : {
    publisher = lower(local.imageDefinitionLinux[0].publisher)
    offer     = lower(local.imageDefinitionLinux[0].offer)
    sku       = lower(local.imageDefinitionLinux[0].sku)
  }
}
