###################################################
# Hammerspace (https://www.hammerspace.com/azure) #
###################################################

locals {
  hsHighAvailability = length(local.hsMetadataNodes) > 1 ? true : false
  hsMetadataNodes = [
    for i in range(var.hammerspace.metadata.machine.count) : merge(var.hammerspace.metadata, {
      machine = merge(var.hammerspace.metadata.machine, {
        index = i
        name  = "${var.hammerspace.namePrefix}${var.hammerspace.metadata.machine.namePrefix}${i + 1}"
        adminLogin = merge(var.hammerspace.metadata.machine.adminLogin, {
          userName     = var.hammerspace.metadata.machine.adminLogin.userName != "" ? var.hammerspace.metadata.machine.adminLogin.userName : var.adminLogin.userName
          userPassword = var.hammerspace.metadata.machine.adminLogin.userPassword != "" ? var.hammerspace.metadata.machine.adminLogin.userPassword : var.adminLogin.userPassword
          sshKeyPublic = var.hammerspace.metadata.machine.adminLogin.sshKeyPublic != "" ? var.hammerspace.metadata.machine.adminLogin.sshKeyPublic : var.adminLogin.sshKeyPublic
        })
      })
    })
  ]
  hsMetadataNodeConfig = {
    cluster = {
      domainname = var.hammerspace.domainName
    }
    node = {
      hostname = ""
      ha_mode  = ""
    }
  }
  hsMetadataNodeConfigHA = local.hsHighAvailability ? merge(local.hsMetadataNodeConfig, {
    node = merge(local.hsMetadataNodeConfig.node, {
      networks = {
        eth0 = {
          cluster_ips = [
            "${azurerm_lb.metadata[0].frontend_ip_configuration[0].private_ip_address}${local.hsSubnetSize}"
          ]
        }
        eth1 = {
          dhcp = true
        }
      }
    })
  }) : null
}

###################################################################################################
# Availability Set (https://learn.microsoft.com/azure/virtual-machines/availability-set-overview) #
###################################################################################################

resource azurerm_availability_set metadata {
  name                         = "${var.hammerspace.namePrefix}${var.hammerspace.metadata.machine.namePrefix}"
  resource_group_name          = var.resourceGroup.name
  location                     = var.resourceGroup.location
  proximity_placement_group_id = var.hammerspace.proximityPlacementGroup.enable ? azurerm_proximity_placement_group.hammerspace[0].id : null
}

#########################################################################
# Virtual Machines (https://learn.microsoft.com/azure/virtual-machines) #
#########################################################################

resource azurerm_network_interface metadata {
  for_each = {
    for node in local.hsMetadataNodes : node.machine.name => node
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

resource azurerm_network_interface metadata_ha {
  for_each = {
    for node in local.hsMetadataNodes : node.machine.name => node if local.hsHighAvailability
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

resource azurerm_linux_virtual_machine metadata {
  for_each = {
    for node in local.hsMetadataNodes : node.machine.name => node
  }
  name                            = each.value.machine.name
  resource_group_name             = var.resourceGroup.name
  location                        = var.resourceGroup.location
  size                            = each.value.machine.size
  admin_username                  = each.value.machine.adminLogin.userName
  admin_password                  = each.value.machine.adminLogin.userPassword
  disable_password_authentication = each.value.machine.adminLogin.passwordAuth.disable
  availability_set_id             = azurerm_availability_set.metadata.id
  proximity_placement_group_id    = var.hammerspace.proximityPlacementGroup.enable ? azurerm_proximity_placement_group.hammerspace[0].id : null
  custom_data = base64encode(jsonencode(
    local.hsHighAvailability ? merge(local.hsMetadataNodeConfigHA, {
      node = {
        hostname = each.value.machine.name
        ha_mode  = each.value.machine.index == 0 ? "Primary" : "Secondary"
      }
    }) : merge(local.hsMetadataNodeConfig, {
      node = {
        hostname = each.value.machine.name
        ha_mode  = "Standalone"
      }
    })
  ))
  network_interface_ids = distinct(local.hsHighAvailability ? [
    azurerm_network_interface.metadata[each.value.machine.name].id,
    azurerm_network_interface.metadata_ha[each.value.machine.name].id
  ] : [
    azurerm_network_interface.metadata[each.value.machine.name].id,
    azurerm_network_interface.metadata[each.value.machine.name].id
  ])
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

resource azurerm_managed_disk metadata {
  for_each = {
    for node in local.hsMetadataNodes : node.machine.name => node
  }
  name                          = each.value.machine.name
  resource_group_name           = var.resourceGroup.name
  location                      = var.resourceGroup.location
  storage_account_type          = each.value.machine.dataDisk.storageType
  disk_size_gb                  = each.value.machine.dataDisk.sizeGB
  public_network_access_enabled = false
  create_option                 = "Empty"
}

resource azurerm_virtual_machine_data_disk_attachment metadata {
  for_each = {
    for node in local.hsMetadataNodes : node.machine.name => node
  }
  virtual_machine_id = "${data.azurerm_resource_group.hammerspace.id}/providers/Microsoft.Compute/virtualMachines/${each.value.machine.name}"
  managed_disk_id    = "${data.azurerm_resource_group.hammerspace.id}/providers/Microsoft.Compute/disks/${each.value.machine.name}"
  caching            = each.value.machine.dataDisk.cachingType
  lun                = 0
  depends_on = [
    azurerm_managed_disk.metadata,
    azurerm_linux_virtual_machine.metadata
  ]
}

##########################################################################################
# Load Balancer (https://learn.microsoft.com/azure/load-balancer/load-balancer-overview) #
##########################################################################################

resource azurerm_lb metadata {
  count               = local.hsHighAvailability ? 1 : 0
  name                = "${var.hammerspace.namePrefix}${var.hammerspace.metadata.machine.namePrefix}"
  resource_group_name = var.resourceGroup.name
  location            = var.resourceGroup.location
  sku                 = "Standard"
  frontend_ip_configuration {
    name      = "ipConfig"
    subnet_id = data.azurerm_subnet.storage.id
  }
}

resource azurerm_lb_backend_address_pool metadata {
  count           = local.hsHighAvailability ? 1 : 0
  name            = "MetadataPool"
  loadbalancer_id = azurerm_lb.metadata[0].id
}

resource azurerm_network_interface_backend_address_pool_association metadata {
  for_each = {
    for node in local.hsMetadataNodes : node.machine.name => node if local.hsHighAvailability
  }
  backend_address_pool_id = azurerm_lb_backend_address_pool.metadata[0].id
  network_interface_id    = "${data.azurerm_resource_group.hammerspace.id}/providers/Microsoft.Network/networkInterfaces/${each.value.machine.name}"
  ip_configuration_name   = "ipConfig"
  depends_on = [
    azurerm_network_interface.metadata
  ]
}

resource azurerm_lb_rule metadata {
  count                          = local.hsHighAvailability ? 1 : 0
  name                           = "MetadataRule"
  loadbalancer_id                = azurerm_lb.metadata[0].id
  frontend_ip_configuration_name = azurerm_lb.metadata[0].frontend_ip_configuration[0].name
  probe_id                       = azurerm_lb_probe.metadata[0].id
  enable_floating_ip             = true
  protocol                       = "All"
  frontend_port                  = 0
  backend_port                   = 0
  backend_address_pool_ids = [
    azurerm_lb_backend_address_pool.metadata[0].id
  ]
}

resource azurerm_lb_probe metadata {
  count           = local.hsHighAvailability ? 1 : 0
  name            = "MetadataProbe"
  loadbalancer_id = azurerm_lb.metadata[0].id
  protocol        = "Tcp"
  port            = 4505
}

############################################################################
# Private DNS (https://learn.microsoft.com/azure/dns/private-dns-overview) #
############################################################################

resource azurerm_private_dns_a_record metadata {
  name                = "${var.privateDns.aRecord.name}-metadata"
  resource_group_name = var.privateDns.resourceGroupName
  zone_name           = var.privateDns.zoneName
  ttl                 = var.privateDns.aRecord.ttlSeconds
  records = local.hsHighAvailability ? [
    azurerm_lb.metadata[0].frontend_ip_configuration[0].private_ip_address
  ] : [
    for node in local.hsMetadataNodes : azurerm_linux_virtual_machine.metadata[node.machine.name].private_ip_address
  ]
}

output dnsMetadata {
  value = {
    fqdn    = azurerm_private_dns_a_record.metadata.fqdn
    records = azurerm_private_dns_a_record.metadata.records
  }
}
