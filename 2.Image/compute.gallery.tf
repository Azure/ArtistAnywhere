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
      support = object({
        networkAcceleration = bool
        machineConfidential = bool
        launchTrusted       = bool
        hibernation         = bool
        nvmeDisks           = bool
      })
    }))
  })
}

locals {
  imageDefinitionLinux = [
    for imageDefinition in var.computeGallery.imageDefinitions : imageDefinition if lower(imageDefinition.type) == "linux"
  ][0]
}

resource azurerm_shared_image_gallery main {
  name                = var.computeGallery.name
  resource_group_name = azurerm_resource_group.image_gallery.name
  location            = azurerm_resource_group.image_gallery.location
}

resource azurerm_shared_image main {
  for_each = {
    for imageDefinition in var.computeGallery.imageDefinitions : imageDefinition.name => imageDefinition if (lower(imageDefinition.type) == "linux") || (module.config.image.windows.cluster.enable && lower(imageDefinition.type) == "windows") || (!module.config.image.windows.cluster.enable && lower(imageDefinition.name) == "winuser")
  }
  name                                = each.value.name
  resource_group_name                 = azurerm_resource_group.image_gallery.name
  location                            = azurerm_resource_group.image_gallery.location
  gallery_name                        = azurerm_shared_image_gallery.main.name
  hyper_v_generation                  = each.value.generation
  os_type                             = each.value.type
  accelerated_network_support_enabled = each.value.support.networkAcceleration
  confidential_vm_supported           = !each.value.support.launchTrusted ? each.value.support.machineConfidential : null
  trusted_launch_supported            = !each.value.support.machineConfidential ? each.value.support.launchTrusted : null
  hibernation_enabled                 = each.value.support.hibernation
  disk_controller_type_nvme_enabled   = each.value.support.nvmeDisks
  identifier {
    publisher = each.value.publisher
    offer     = each.value.offer
    sku       = each.value.sku
  }
}

output linux {
  value = {
    publisher = lower(local.imageDefinitionLinux.publisher)
    offer     = lower(local.imageDefinitionLinux.offer)
    sku       = lower(local.imageDefinitionLinux.sku)
    version   = module.config.image.linux.version
  }
}
