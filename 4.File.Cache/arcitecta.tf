#############################################################
# Arcitecta Mediaflux (https://www.arcitecta.com/mediaflux) #
#############################################################

variable mediaflux {
  type = object({
    enable = bool
    name   = string
    machine = object({
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
    })
    network = object({
      acceleration = object({
        enable = bool
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
}

locals {
  mediaflux = [
    for i in range(var.mediaflux.machine.count) : merge(var.mediaflux, {
      machine = merge(var.mediaflux.machine, {
        name = "${var.mediaflux.name}-${i}"
        image = merge(var.mediaflux.machine.image, {
          plan = {
            publisher = try(data.terraform_remote_state.image.outputs.linuxPlan.publisher, var.mediaflux.machine.image.plan.publisher)
            product   = try(data.terraform_remote_state.image.outputs.linuxPlan.offer, var.mediaflux.machine.image.plan.product)
            name      = try(data.terraform_remote_state.image.outputs.linuxPlan.sku, var.mediaflux.machine.image.plan.name)
          }
        })
      })
    })
  ]
}

resource azurerm_resource_group arcitecta {
  count    = var.mediaflux.enable ? 1 : 0
  name     = "${var.resourceGroupName}.Arcitecta"
  location = var.existingNetwork.enable ? var.existingNetwork.regionName : module.global.resourceLocation.regionName
}

resource azurerm_proximity_placement_group mediaflux {
  count               = var.mediaflux.enable ? 1 : 0
  name                = var.mediaflux.name
  resource_group_name = azurerm_resource_group.arcitecta[0].name
  location            = azurerm_resource_group.arcitecta[0].location
}

resource azurerm_availability_set mediaflux {
  count                        = var.mediaflux.enable ? 1 : 0
  name                         = var.mediaflux.name
  resource_group_name          = azurerm_resource_group.arcitecta[0].name
  location                     = azurerm_resource_group.arcitecta[0].location
  proximity_placement_group_id = azurerm_proximity_placement_group.mediaflux[0].id
}

resource azurerm_network_interface mediaflux {
  for_each = {
    for cacheNode in local.mediaflux : cacheNode.machine.name => cacheNode if var.mediaflux.enable
  }
  name                = each.value.machine.name
  resource_group_name = azurerm_resource_group.arcitecta[0].name
  location            = azurerm_resource_group.arcitecta[0].location
  ip_configuration {
    name                          = "ipConfig"
    subnet_id                     = data.azurerm_subnet.cache.id
    private_ip_address_allocation = "Dynamic"
  }
  accelerated_networking_enabled = each.value.network.acceleration.enable
  lifecycle {
    prevent_destroy = true
  }
}

resource azurerm_linux_virtual_machine mediaflux {
  for_each = {
    for cacheNode in local.mediaflux : cacheNode.machine.name => cacheNode if var.mediaflux.enable
  }
  name                            = each.value.machine.name
  resource_group_name             = azurerm_resource_group.arcitecta[0].name
  location                        = azurerm_resource_group.arcitecta[0].location
  source_image_id                 = "/subscriptions/${data.azurerm_client_config.studio.subscription_id}/resourceGroups/${each.value.machine.image.resourceGroupName}/providers/Microsoft.Compute/galleries/${each.value.machine.image.galleryName}/images/${each.value.machine.image.definitionName}/versions/${each.value.machine.image.versionId}"
  size                            = each.value.machine.size
  admin_username                  = each.value.adminLogin.userName
  admin_password                  = each.value.adminLogin.userPassword
  availability_set_id             = azurerm_availability_set.mediaflux[0].id
  proximity_placement_group_id    = azurerm_proximity_placement_group.mediaflux[0].id
  disable_password_authentication = false
  network_interface_ids = [
    "${azurerm_resource_group.arcitecta[0].id}/providers/Microsoft.Network/networkInterfaces/${each.value.machine.name}"
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
    for_each = each.value.machine.image.plan.publisher != "" ? [1] : []
    content {
      publisher = each.value.machine.image.plan.publisher
      product   = each.value.machine.image.plan.product
      name      = each.value.machine.image.plan.name
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
