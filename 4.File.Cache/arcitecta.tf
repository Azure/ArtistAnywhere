#############################################################
# Arcitecta Mediaflux (https://www.arcitecta.com/mediaflux) #
#############################################################

variable mediaflux {
  type = object({
    enable = bool
    name   = string
    node = object({
      size  = string
      count = number
      image = object({
        resourceGroupName = string
        galleryName       = string
        definitionName    = string
        versionId         = string
        plan = object({
          publisher = string
          product   = string
          name      = string
        })
      })
      osDisk = object({
        storageType = string
        cachingType = string
        sizeGB      = number
      })
      dataDisk = object({
        size = number
      })
      adminLogin = object({
        userName     = string
        userPassword = string
      })
    })
  })
}

locals {
  cacheCluster = [
    for i in range(var.mediaflux.node.count) : merge(var.mediaflux.node, {
      name = "${var.mediaflux.name}-${i}"
      image = merge(var.mediaflux.node.image, {
        plan = {
          publisher = try(data.terraform_remote_state.image.outputs.linuxPlan.publisher, var.mediaflux.node.image.plan.publisher)
          product   = try(data.terraform_remote_state.image.outputs.linuxPlan.offer, var.mediaflux.node.image.plan.product)
          name      = try(data.terraform_remote_state.image.outputs.linuxPlan.sku, var.mediaflux.node.image.plan.name)
        }
      })
    })
  ]
}

resource azurerm_resource_group arcitecta {
  name     = "${var.resourceGroupName}.Arcitecta"
  location = var.existingNetwork.enable ? var.existingNetwork.regionName : module.global.resourceLocation.regionName
}

resource azurerm_proximity_placement_group mediaflux {
  count               = var.mediaflux.enable ? 1 : 0
  name                = var.mediaflux.name
  resource_group_name = azurerm_resource_group.arcitecta.name
  location            = azurerm_resource_group.arcitecta.location
}

resource azurerm_availability_set mediaflux {
  count                        = var.mediaflux.enable ? 1 : 0
  name                         = var.mediaflux.name
  resource_group_name          = azurerm_resource_group.arcitecta.name
  location                     = azurerm_resource_group.arcitecta.location
  proximity_placement_group_id = azurerm_proximity_placement_group.mediaflux[0].id
}

resource azurerm_network_interface mediaflux {
  for_each = {
    for cacheNode in local.cacheCluster : cacheNode.name => cacheNode
  }
  name                = each.value.name
  resource_group_name = azurerm_resource_group.arcitecta.name
  location            = azurerm_resource_group.arcitecta.location
  ip_configuration {
    name                          = "ipConfig"
    subnet_id                     = data.azurerm_subnet.cache.id
    private_ip_address_allocation = "Dynamic"
  }
  enable_accelerated_networking = true
  lifecycle {
    prevent_destroy = true
  }
}

resource azurerm_linux_virtual_machine mediaflux {
  for_each = {
    for cacheNode in local.cacheCluster : cacheNode.name => cacheNode if var.mediaflux.enable
  }
  name                            = each.value.name
  resource_group_name             = azurerm_resource_group.arcitecta.name
  location                        = azurerm_resource_group.arcitecta.location
  source_image_id                 = "/subscriptions/${data.azurerm_client_config.studio.subscription_id}/resourceGroups/${each.value.image.resourceGroupName}/providers/Microsoft.Compute/galleries/${each.value.image.galleryName}/images/${each.value.image.definitionName}/versions/${each.value.image.versionId}"
  size                            = each.value.size
  admin_username                  = each.value.adminLogin.userName
  admin_password                  = each.value.adminLogin.userPassword
  availability_set_id             = azurerm_availability_set.mediaflux[0].id
  proximity_placement_group_id    = azurerm_proximity_placement_group.mediaflux[0].id
  disable_password_authentication = false
  network_interface_ids = [
    "${azurerm_resource_group.arcitecta.id}/providers/Microsoft.Network/networkInterfaces/${each.value.name}"
  ]
  os_disk {
    storage_account_type = each.value.osDisk.storageType
    caching              = each.value.osDisk.cachingType
    disk_size_gb         = each.value.osDisk.sizeGB > 0 ? each.value.osDisk.sizeGB : null
  }
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  dynamic plan {
    for_each = each.value.image.plan.publisher != "" ? [1] : []
    content {
      publisher = each.value.image.plan.publisher
      product   = each.value.image.plan.product
      name      = each.value.image.plan.name
    }
  }
  depends_on = [
    azurerm_network_interface.mediaflux
  ]
}

output macAddresses {
  value = var.mediaflux.enable ? [
    for nic in azurerm_network_interface.mediaflux : nic.mac_address
  ] : null
}
