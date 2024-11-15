######################################################################################################
# Hammerspace (https://azuremarketplace.microsoft.com/marketplace/apps/hammerspace.hammerspace-byol) #
######################################################################################################

variable hsCache {
  type = object({
    enable     = bool
    version    = string
    namePrefix = string
    domainName = string
    activeDirectory = object({
      enable   = bool
      realm    = string
      orgUnit  = string
      username = string
      password = string
    })
    metadata = object({
      machine = object({
        namePrefix = string
        size       = string
        count      = number
        adminLogin = object({
          userName     = string
          userPassword = string
          sshKeyPublic = string
          passwordAuth = object({
            disable = bool
          })
        })
        osDisk = object({
          storageType = string
          cachingType = string
          sizeGB      = number
        })
        dataDisk = object({
          storageType = string
          cachingType = string
          sizeGB      = number
        })
      })
      network = object({
        acceleration = object({
          enable = bool
        })
      })
    })
    data = object({
      machine = object({
        namePrefix = string
        size       = string
        count      = number
        adminLogin = object({
          userName     = string
          userPassword = string
          sshKeyPublic = string
          passwordAuth = object({
            disable = bool
          })
        })
        osDisk = object({
          storageType = string
          cachingType = string
          sizeGB      = number
        })
        dataDisk = object({
          storageType = string
          cachingType = string
          sizeGB      = number
          count       = number
          raid0 = object({
            enable = bool
          })
        })
      })
      network = object({
        acceleration = object({
          enable = bool
        })
      })
    })
    proximityPlacementGroup = object({
      enable = bool
    })
    privateDnsTier = object({
      metadata = bool
    })
    shares = list(object({
      enable = bool
      name   = string
      path   = string
      size   = number
      export = string
    }))
    storageTargets = list(object({
      enable = bool
      node = object({
        name = string
        type = string
        ip   = string
      })
      volume = object({
        name      = string
        type      = string
        path      = string
        shareName = string
      })
    }))
    volumeGroups = list(object({
      enable      = bool
      name        = string
      volumeNames = list(string)
    }))
  })
}

locals {
  hsImage = {
    publisher = "Hammerspace"
    product   = "Hammerspace_BYOL_5_0"
    name      = "Hammerspace_5_0"
    version   = var.hsCache.version
  }
  hsActiveDirectory = merge(var.hsCache.activeDirectory, {
    username = var.hsCache.activeDirectory.username != "" ? var.hsCache.activeDirectory.username : data.azurerm_key_vault_secret.admin_username.value
    password = var.hsCache.activeDirectory.password != "" ? var.hsCache.activeDirectory.password : data.azurerm_key_vault_secret.admin_password.value
  })
  hsCacheSubnetSize  = "/${reverse(split("/", data.azurerm_subnet.cache.address_prefixes[0]))[0]}"
  hsHighAvailability = var.hsCache.enable && length(local.hsMetadataNodes) > 1 ? true : false
  hsMetadataNodes = [
    for i in range(var.hsCache.metadata.machine.count) : merge(var.hsCache.metadata, {
      machine = merge(var.hsCache.metadata.machine, {
        index = i
        name  = "${var.hsCache.namePrefix}${var.hsCache.metadata.machine.namePrefix}${i + 1}"
        adminLogin = merge(var.hsCache.metadata.machine.adminLogin, {
          userName     = var.hsCache.metadata.machine.adminLogin.userName != "" ? var.hsCache.metadata.machine.adminLogin.userName : data.azurerm_key_vault_secret.admin_username.value
          userPassword = var.hsCache.metadata.machine.adminLogin.userPassword != "" ? var.hsCache.metadata.machine.adminLogin.userPassword : data.azurerm_key_vault_secret.admin_password.value
          sshKeyPublic = var.hsCache.metadata.machine.adminLogin.sshKeyPublic != "" ? var.hsCache.metadata.machine.adminLogin.sshKeyPublic : data.azurerm_key_vault_secret.ssh_key_public.value
        })
      })
    }) if var.hsCache.enable
  ]
  hsDataNodes = [
    for i in range(var.hsCache.data.machine.count) : merge(var.hsCache.data, {
      machine = merge(var.hsCache.data.machine, {
        index = i
        name  = "${var.hsCache.namePrefix}${var.hsCache.data.machine.namePrefix}${i + 1}"
        adminLogin = merge(var.hsCache.data.machine.adminLogin, {
          userName     = var.hsCache.data.machine.adminLogin.userName != "" ? var.hsCache.data.machine.adminLogin.userName : data.azurerm_key_vault_secret.admin_username.value
          userPassword = var.hsCache.data.machine.adminLogin.userPassword != "" ? var.hsCache.data.machine.adminLogin.userPassword : data.azurerm_key_vault_secret.admin_password.value
          sshKeyPublic = var.hsCache.data.machine.adminLogin.sshKeyPublic != "" ? var.hsCache.data.machine.adminLogin.sshKeyPublic : data.azurerm_key_vault_secret.ssh_key_public.value
        })
      })
    }) if var.hsCache.enable
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
  hsMetadataNodeConfig = var.hsCache.enable ? {
    cluster = {
      domainname = var.hsCache.domainName
    }
    node = {
      hostname = ""
      ha_mode  = ""
    }
  } : null
  hsMetadataNodeConfigHA = local.hsHighAvailability ? merge(local.hsMetadataNodeConfig, {
    node = merge(local.hsMetadataNodeConfig.node, {
      networks = {
        eth0 = {
          cluster_ips = [
            "${azurerm_lb.hs_metadata[0].frontend_ip_configuration[0].private_ip_address}${local.hsCacheSubnetSize}"
          ]
        }
        eth1 = {
          dhcp = true
        }
      }
    })
  }) : null
  hsDataNodeConfig = var.hsCache.enable ? {
    cluster = {
      domainname = var.hsCache.domainName
      metadata = {
        ips = [
          "${local.hsHighAvailability ? azurerm_lb.hs_metadata[0].frontend_ip_configuration[0].private_ip_address : azurerm_linux_virtual_machine.hs_metadata[local.hsMetadataNodes[0].machine.name].private_ip_address}${local.hsCacheSubnetSize}"
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
        options = var.hsCache.data.machine.dataDisk.raid0.enable && var.hsCache.data.machine.dataDisk.count > 1 ? ["raid0"] : []
      }
      add_volumes = true
    }
  } : null
}

####################################################################################################
# Availability Sets (https://learn.microsoft.com/azure/virtual-machines/availability-set-overview) #
####################################################################################################

resource azurerm_availability_set hs_metadata {
  count                        = var.hsCache.enable ? 1 : 0
  name                         = "${var.hsCache.namePrefix}${var.hsCache.metadata.machine.namePrefix}"
  resource_group_name          = azurerm_resource_group.cache.name
  location                     = azurerm_resource_group.cache.location
  proximity_placement_group_id = var.hsCache.proximityPlacementGroup.enable ? azurerm_proximity_placement_group.hs[0].id : null
}

resource azurerm_availability_set hs_data {
  count                        = var.hsCache.enable ? 1 : 0
  name                         = "${var.hsCache.namePrefix}${var.hsCache.data.machine.namePrefix}"
  resource_group_name          = azurerm_resource_group.cache.name
  location                     = azurerm_resource_group.cache.location
  proximity_placement_group_id = var.hsCache.proximityPlacementGroup.enable ? azurerm_proximity_placement_group.hs[0].id : null
}

###############################################################################################
# Proximity Placement Groups (https://learn.microsoft.com/azure/virtual-machines/co-location) #
###############################################################################################

resource azurerm_proximity_placement_group hs {
  count               = var.hsCache.enable && var.hsCache.proximityPlacementGroup.enable ? 1 : 0
  name                = var.hsCache.namePrefix
  location            = azurerm_resource_group.cache.location
  resource_group_name = azurerm_resource_group.cache.name
}

#########################################################################
# Virtual Machines (https://learn.microsoft.com/azure/virtual-machines) #
#########################################################################

resource azurerm_network_interface hs_metadata {
  for_each = {
    for node in local.hsMetadataNodes : node.machine.name => node
  }
  name                = each.value.machine.name
  resource_group_name = azurerm_resource_group.cache.name
  location            = azurerm_resource_group.cache.location
  ip_configuration {
    name                          = "ipConfig"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = data.azurerm_subnet.cache.id
  }
  accelerated_networking_enabled = each.value.network.acceleration.enable
}

resource azurerm_network_interface hs_metadata_ha {
  for_each = {
    for node in local.hsMetadataNodes : node.machine.name => node if local.hsHighAvailability
  }
  name                = each.value.machine.name
  resource_group_name = azurerm_resource_group.cache.name
  location            = azurerm_resource_group.cache.location
  ip_configuration {
    name                          = "ipConfig"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = data.azurerm_subnet.cache_ha.id
  }
  accelerated_networking_enabled = each.value.network.acceleration.enable
}

resource azurerm_network_interface hs_data {
  for_each = {
    for node in local.hsDataNodes : node.machine.name => node
  }
  name                = each.value.machine.name
  resource_group_name = azurerm_resource_group.cache.name
  location            = azurerm_resource_group.cache.location
  ip_configuration {
    name                          = "ipConfig"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = data.azurerm_subnet.cache.id
  }
  accelerated_networking_enabled = each.value.network.acceleration.enable
}

resource azurerm_linux_virtual_machine hs_metadata {
  for_each = {
    for node in local.hsMetadataNodes : node.machine.name => node
  }
  name                            = each.value.machine.name
  resource_group_name             = azurerm_resource_group.cache.name
  location                        = azurerm_resource_group.cache.location
  size                            = each.value.machine.size
  admin_username                  = each.value.machine.adminLogin.userName
  admin_password                  = each.value.machine.adminLogin.userPassword
  disable_password_authentication = each.value.machine.adminLogin.passwordAuth.disable
  availability_set_id             = azurerm_availability_set.hs_metadata[0].id
  proximity_placement_group_id    = var.hsCache.proximityPlacementGroup.enable ? azurerm_proximity_placement_group.hs[0].id : null
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
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  network_interface_ids = distinct(local.hsHighAvailability ? [
    azurerm_network_interface.hs_metadata[each.value.machine.name].id,
    azurerm_network_interface.hs_metadata_ha[each.value.machine.name].id
  ] : [
    azurerm_network_interface.hs_metadata[each.value.machine.name].id,
    azurerm_network_interface.hs_metadata[each.value.machine.name].id
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

resource azurerm_linux_virtual_machine hs_data {
  for_each = {
    for node in local.hsDataNodes : node.machine.name => node
  }
  name                            = each.value.machine.name
  resource_group_name             = azurerm_resource_group.cache.name
  location                        = azurerm_resource_group.cache.location
  size                            = each.value.machine.size
  admin_username                  = each.value.machine.adminLogin.userName
  admin_password                  = each.value.machine.adminLogin.userPassword
  disable_password_authentication = each.value.machine.adminLogin.passwordAuth.disable
  availability_set_id             = azurerm_availability_set.hs_data[0].id
  proximity_placement_group_id    = var.hsCache.proximityPlacementGroup.enable ? azurerm_proximity_placement_group.hs[0].id : null
  custom_data = base64encode(jsonencode(
    merge(local.hsDataNodeConfig, {
      node = merge(local.hsDataNodeConfig.node, {
        hostname = each.value.machine.name
      })
    })
  ))
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  network_interface_ids = [
    azurerm_network_interface.hs_data[each.value.machine.name].id
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

resource azurerm_managed_disk hs_metadata {
  for_each = {
    for node in local.hsMetadataNodes : node.machine.name => node
  }
  name                          = each.value.machine.name
  resource_group_name           = azurerm_resource_group.cache.name
  location                      = azurerm_resource_group.cache.location
  storage_account_type          = each.value.machine.dataDisk.storageType
  disk_size_gb                  = each.value.machine.dataDisk.sizeGB
  public_network_access_enabled = false
  create_option                 = "Empty"
}

resource azurerm_managed_disk hs_data {
  for_each = {
    for disk in local.hsDataNodeDisks : disk.machine.dataDisk.name => disk
  }
  name                          = each.value.machine.dataDisk.name
  resource_group_name           = azurerm_resource_group.cache.name
  location                      = azurerm_resource_group.cache.location
  storage_account_type          = each.value.machine.dataDisk.storageType
  disk_size_gb                  = each.value.machine.dataDisk.sizeGB
  public_network_access_enabled = false
  create_option                 = "Empty"
}

resource azurerm_virtual_machine_data_disk_attachment hs_metadata {
  for_each = {
    for node in local.hsMetadataNodes : node.machine.name => node
  }
  virtual_machine_id = "${azurerm_resource_group.cache.id}/providers/Microsoft.Compute/virtualMachines/${each.value.machine.name}"
  managed_disk_id    = "${azurerm_resource_group.cache.id}/providers/Microsoft.Compute/disks/${each.value.machine.name}"
  caching            = each.value.machine.dataDisk.cachingType
  lun                = 0
  depends_on = [
    azurerm_managed_disk.hs_metadata,
    azurerm_linux_virtual_machine.hs_metadata
  ]
}

resource azurerm_virtual_machine_data_disk_attachment hs_data {
  for_each = {
    for disk in local.hsDataNodeDisks : disk.machine.dataDisk.name => disk
  }
  virtual_machine_id = "${azurerm_resource_group.cache.id}/providers/Microsoft.Compute/virtualMachines/${each.value.machine.name}"
  managed_disk_id    = "${azurerm_resource_group.cache.id}/providers/Microsoft.Compute/disks/${each.value.machine.dataDisk.name}"
  caching            = each.value.machine.dataDisk.cachingType
  lun                = each.value.machine.dataDisk.index
  depends_on = [
    azurerm_managed_disk.hs_data,
    azurerm_linux_virtual_machine.hs_data
  ]
}

resource azurerm_virtual_machine_extension hs_node {
  for_each = {
    for node in concat(local.hsMetadataNodes, local.hsDataNodes) : node.machine.name => node
  }
  name                       = "Initialize"
  type                       = "CustomScript"
  publisher                  = "Microsoft.Azure.Extensions"
  type_handler_version       = "2.1"
  automatic_upgrade_enabled  = false
  auto_upgrade_minor_version = true
  virtual_machine_id         = "${azurerm_resource_group.cache.id}/providers/Microsoft.Compute/virtualMachines/${each.value.machine.name}"
  protected_settings = jsonencode({
    script = base64encode(
      templatefile("hs.node.sh", {
        adminPassword = each.value.machine.adminLogin.userPassword
      })
    )
  })
  depends_on = [
    azurerm_virtual_machine_data_disk_attachment.hs_metadata,
    azurerm_virtual_machine_data_disk_attachment.hs_data
  ]
}

resource terraform_data hs_cluster_initialize {
  count = var.hsCache.enable ? 1 : 0
  provisioner local-exec {
    command = "az vm extension set --resource-group ${azurerm_resource_group.cache.name} --vm-name ${local.hsMetadataNodes[0].machine.name} --name CustomScript --publisher Microsoft.Azure.Extensions --protected-settings ${jsonencode({script = base64encode(templatefile("hs.cluster.init.sh", {}))})}"
  }
  depends_on = [
    azurerm_virtual_machine_extension.hs_node
  ]
}

resource terraform_data hs_cluster_node {
  for_each = {
    for node in concat(local.hsMetadataNodes, local.hsDataNodes) : node.machine.name => node
  }
  provisioner local-exec {
    command = "az vm extension set --resource-group ${azurerm_resource_group.cache.name} --vm-name ${each.value.machine.name} --name CustomScript --publisher Microsoft.Azure.Extensions --protected-settings ${jsonencode({script = base64encode(templatefile("hs.cluster.node.sh", {activeDirectory = local.hsActiveDirectory}))})}"
  }
  depends_on = [
    terraform_data.hs_cluster_initialize
  ]
}

resource terraform_data hs_cluster_data {
  count = var.hsCache.enable ? 1 : 0
  provisioner local-exec {
    command = "az vm extension set --resource-group ${azurerm_resource_group.cache.name} --vm-name ${local.hsMetadataNodes[0].machine.name} --name CustomScript --publisher Microsoft.Azure.Extensions --protected-settings ${jsonencode({script = base64encode(templatefile("hs.cluster.data.sh", {shares = var.hsCache.shares, storageTargets = var.hsCache.storageTargets, volumeGroups = var.hsCache.volumeGroups}))})}"
  }
  depends_on = [
    terraform_data.hs_cluster_node
  ]
}

##########################################################################################
# Load Balancer (https://learn.microsoft.com/azure/load-balancer/load-balancer-overview) #
##########################################################################################

resource azurerm_lb hs_metadata {
  count               = local.hsHighAvailability ? 1 : 0
  name                = "${var.hsCache.namePrefix}${var.hsCache.metadata.machine.namePrefix}"
  resource_group_name = azurerm_resource_group.cache.name
  location            = azurerm_resource_group.cache.location
  sku                 = "Standard"
  frontend_ip_configuration {
    name      = "ipConfig"
    subnet_id = data.azurerm_subnet.cache.id
  }
}

resource azurerm_lb hs_data {
  name                = "${var.hsCache.namePrefix}${var.hsCache.data.machine.namePrefix}"
  resource_group_name = azurerm_resource_group.cache.name
  location            = azurerm_resource_group.cache.location
  sku                 = "Standard"
  frontend_ip_configuration {
    name      = "ipConfig"
    subnet_id = data.azurerm_subnet.cache.id
  }
}

resource azurerm_lb_backend_address_pool hs_metadata {
  count           = local.hsHighAvailability ? 1 : 0
  name            = "MetadataPool"
  loadbalancer_id = azurerm_lb.hs_metadata[0].id
}

resource azurerm_lb_backend_address_pool hs_data {
  name            = "DataPool"
  loadbalancer_id = azurerm_lb.hs_data.id
}

resource azurerm_network_interface_backend_address_pool_association hs_metadata {
  for_each = {
    for node in local.hsMetadataNodes : node.machine.name => node if local.hsHighAvailability
  }
  backend_address_pool_id = azurerm_lb_backend_address_pool.hs_metadata[0].id
  network_interface_id    = "${azurerm_resource_group.cache.id}/providers/Microsoft.Network/networkInterfaces/${each.value.machine.name}"
  ip_configuration_name   = "ipConfig"
  depends_on = [
    azurerm_network_interface.hs_metadata
  ]
}

resource azurerm_network_interface_backend_address_pool_association hs_data {
  for_each = {
    for node in local.hsDataNodes : node.machine.name => node
  }
  backend_address_pool_id = azurerm_lb_backend_address_pool.hs_data.id
  network_interface_id    = "${azurerm_resource_group.cache.id}/providers/Microsoft.Network/networkInterfaces/${each.value.machine.name}"
  ip_configuration_name   = "ipConfig"
  depends_on = [
    azurerm_network_interface.hs_data
  ]
}

resource azurerm_lb_rule hs_metadata {
  count                          = local.hsHighAvailability ? 1 : 0
  name                           = "MetadataRule"
  loadbalancer_id                = azurerm_lb.hs_metadata[0].id
  frontend_ip_configuration_name = azurerm_lb.hs_metadata[0].frontend_ip_configuration[0].name
  probe_id                       = azurerm_lb_probe.hs_metadata[0].id
  enable_floating_ip             = true
  protocol                       = "All"
  frontend_port                  = 0
  backend_port                   = 0
  backend_address_pool_ids = [
    azurerm_lb_backend_address_pool.hs_metadata[0].id
  ]
}

resource azurerm_lb_rule hs_data {
  name                           = "DataRule"
  loadbalancer_id                = azurerm_lb.hs_data.id
  frontend_ip_configuration_name = azurerm_lb.hs_data.frontend_ip_configuration[0].name
  probe_id                       = azurerm_lb_probe.hs_data.id
  enable_floating_ip             = true
  protocol                       = "All"
  frontend_port                  = 0
  backend_port                   = 0
  backend_address_pool_ids = [
    azurerm_lb_backend_address_pool.hs_data.id
  ]
}

resource azurerm_lb_probe hs_metadata {
  count           = local.hsHighAvailability ? 1 : 0
  name            = "MetadataProbe"
  loadbalancer_id = azurerm_lb.hs_metadata[0].id
  protocol        = "Tcp"
  port            = 4505
}

resource azurerm_lb_probe hs_data {
  name            = "DataProbe"
  loadbalancer_id = azurerm_lb.hs_data.id
  protocol        = "Tcp"
  port            = 4505
}

############################################################################
# Private DNS (https://learn.microsoft.com/azure/dns/private-dns-overview) #
############################################################################

resource azurerm_private_dns_a_record cache_hs {
  count               = var.hsCache.enable ? 1 : 0
  name                = var.dnsRecord.name
  resource_group_name = var.existingNetwork.enable ? var.existingNetwork.resourceGroupName : data.azurerm_private_dns_zone.studio.resource_group_name
  zone_name           = var.existingNetwork.enable ? var.existingNetwork.privateDns.zoneName : data.azurerm_private_dns_zone.studio.name
  records             = [var.hsCache.privateDnsTier.metadata ? local.hsHighAvailability ? azurerm_lb.hs_metadata[0].frontend_ip_configuration[0].private_ip_address : azurerm_linux_virtual_machine.hs_metadata[local.hsMetadataNodes[0].machine.name].private_ip_address : azurerm_lb.hs_data[0].frontend_ip_configuration[0].private_ip_address]
  ttl                 = var.dnsRecord.ttlSeconds
}

output hsCachePortal {
  value = var.hsCache.enable ? {
    ip = azurerm_linux_virtual_machine.hs_metadata[local.hsMetadataNodes[0].machine.name].private_ip_address
  } : null
}

output hsCacheDNS {
  value = var.hsCache.enable ? {
    fqdn    = azurerm_private_dns_a_record.cache_hs[0].fqdn
    records = azurerm_private_dns_a_record.cache_hs[0].records
  } : null
}
