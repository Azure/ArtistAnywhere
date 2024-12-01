###################################################
# Hammerspace (https://www.hammerspace.com/azure) #
###################################################

locals {
  hsDataNodes = [
    for i in range(var.hammerspace.data.machine.count) : merge(var.hammerspace.data, {
      machine = merge(var.hammerspace.data.machine, {
        index = i
        name  = "${var.hammerspace.namePrefix}${var.hammerspace.data.machine.namePrefix}${i + 1}"
        adminLogin = merge(var.hammerspace.data.machine.adminLogin, {
          userName     = var.hammerspace.data.machine.adminLogin.userName != "" ? var.hammerspace.data.machine.adminLogin.userName : var.adminLogin.userName
          userPassword = var.hammerspace.data.machine.adminLogin.userPassword != "" ? var.hammerspace.data.machine.adminLogin.userPassword : var.adminLogin.userPassword
          sshKeyPublic = var.hammerspace.data.machine.adminLogin.sshKeyPublic != "" ? var.hammerspace.data.machine.adminLogin.sshKeyPublic : var.adminLogin.sshKeyPublic
        })
      })
    })
  ]
  hsDataNodeDisks = flatten([
    for node in local.hsDataNodes : [
      for i in range(node.machine.dataDisk.count) : merge(node, {
        machine = merge(node.machine, {
          dataDisk = merge(node.machine.dataDisk, {
            index = i
            name  = "${node.machine.name}-data${i + 1}"
          })
        })
      })
    ]
  ])
  hsDataNodeConfig = {
    cluster = {
      domainname = var.hammerspace.domainName
      metadata = {
        ips = [
          "${local.hsHighAvailability ? azurerm_lb.metadata[0].frontend_ip_configuration[0].private_ip_address : azurerm_linux_virtual_machine.metadata[local.hsMetadataNodes[0].machine.name].private_ip_address}${local.hsSubnetSize}"
        ]
      }
    }
    node = {
      hostname = ""
      features = [
        "portal",
        "storage"
      ]
      storage = {
        options = var.hammerspace.data.machine.dataDisk.raid0.enable && var.hammerspace.data.machine.dataDisk.count > 1 ? ["raid0"] : []
      }
      add_volumes = true
    }
  }
}

###################################################################################################
# Availability Set (https://learn.microsoft.com/azure/virtual-machines/availability-set-overview) #
###################################################################################################

resource azurerm_availability_set data {
  name                         = "${var.hammerspace.namePrefix}${var.hammerspace.data.machine.namePrefix}"
  resource_group_name          = var.resourceGroup.name
  location                     = var.resourceGroup.location
  proximity_placement_group_id = var.hammerspace.proximityPlacementGroup.enable ? azurerm_proximity_placement_group.hammerspace[0].id : null
}

#########################################################################
# Virtual Machines (https://learn.microsoft.com/azure/virtual-machines) #
#########################################################################

resource azurerm_network_interface data {
  for_each = {
    for node in local.hsDataNodes : node.machine.name => node
  }
  name                = each.value.machine.name
  resource_group_name = var.resourceGroup.name
  location            = var.resourceGroup.location
  ip_configuration {
    name                          = "ipConfig"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = data.azurerm_subnet.storage.id
  }
  accelerated_networking_enabled = each.value.network.acceleration.enable
}

resource azurerm_linux_virtual_machine data {
  for_each = {
    for node in local.hsDataNodes : node.machine.name => node
  }
  name                            = each.value.machine.name
  resource_group_name             = var.resourceGroup.name
  location                        = var.resourceGroup.location
  size                            = each.value.machine.size
  admin_username                  = each.value.machine.adminLogin.userName
  admin_password                  = each.value.machine.adminLogin.userPassword
  disable_password_authentication = each.value.machine.adminLogin.passwordAuth.disable
  availability_set_id             = azurerm_availability_set.data.id
  proximity_placement_group_id    = var.hammerspace.proximityPlacementGroup.enable ? azurerm_proximity_placement_group.hammerspace[0].id : null
  custom_data = base64encode(jsonencode(
    merge(local.hsDataNodeConfig, {
      node = merge(local.hsDataNodeConfig.node, {
        hostname = each.value.machine.name
      })
    })
  ))
  network_interface_ids = [
    azurerm_network_interface.data[each.value.machine.name].id
  ]
  os_disk {
    storage_account_type = each.value.machine.osDisk.storageType
    caching              = each.value.machine.osDisk.cachingType
    disk_size_gb         = each.value.machine.osDisk.sizeGB > 0 ? each.value.machine.osDisk.sizeGB : null
  }
  source_image_reference {
    publisher = local.hsImage.publisher
    offer     = local.hsImage.product
    sku       = local.hsImage.name
    version   = local.hsImage.version
  }
  plan {
    publisher = lower(local.hsImage.publisher)
    product   = lower(local.hsImage.product)
    name      = lower(local.hsImage.name)
  }
  dynamic admin_ssh_key {
    for_each = each.value.machine.adminLogin.sshKeyPublic != "" ? [1] : []
    content {
      username   = each.value.machine.adminLogin.userName
      public_key = each.value.machine.adminLogin.sshKeyPublic
    }
  }
}

resource azurerm_managed_disk data {
  for_each = {
    for disk in local.hsDataNodeDisks : disk.machine.dataDisk.name => disk
  }
  name                          = each.value.machine.dataDisk.name
  resource_group_name           = var.resourceGroup.name
  location                      = var.resourceGroup.location
  storage_account_type          = each.value.machine.dataDisk.storageType
  disk_size_gb                  = each.value.machine.dataDisk.sizeGB
  public_network_access_enabled = false
  create_option                 = "Empty"
}

resource azurerm_virtual_machine_data_disk_attachment data {
  for_each = {
    for disk in local.hsDataNodeDisks : disk.machine.dataDisk.name => disk
  }
  virtual_machine_id = "${data.azurerm_resource_group.hammerspace.id}/providers/Microsoft.Compute/virtualMachines/${each.value.machine.name}"
  managed_disk_id    = "${data.azurerm_resource_group.hammerspace.id}/providers/Microsoft.Compute/disks/${each.value.machine.dataDisk.name}"
  caching            = each.value.machine.dataDisk.cachingType
  lun                = each.value.machine.dataDisk.index
  depends_on = [
    azurerm_managed_disk.data,
    azurerm_linux_virtual_machine.data
  ]
}

############################################################################
# Private DNS (https://learn.microsoft.com/azure/dns/private-dns-overview) #
############################################################################

resource azurerm_private_dns_a_record data {
  name                = "${var.privateDns.aRecord.name}-data"
  resource_group_name = var.privateDns.resourceGroupName
  zone_name           = var.privateDns.zoneName
  records             = [for node in local.hsDataNodes : azurerm_linux_virtual_machine.data[node.machine.name].private_ip_address]
  ttl                 = var.privateDns.aRecord.ttlSeconds
}

output dnsData {
  value = {
    fqdn    = azurerm_private_dns_a_record.data.fqdn
    records = azurerm_private_dns_a_record.data.records
  }
}
