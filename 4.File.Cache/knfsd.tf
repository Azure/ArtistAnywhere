variable knfsdCache {
  type = object({
    enable = bool
    name   = string
    machine = object({
      size = string
      image = object({
        publisher = string
        product   = string
        name      = string
        version   = string
      })
      osDisk = object({
        storageType = string
        cachingType = string
        sizeGB      = number
        ephemeral = object({
          enable    = bool
          placement = string
        })
      })
      dataDisk = object({
        enable      = bool
        storageType = string
        cachingType = string
        sizeGB      = number
      })
      adminLogin = object({
        userName     = string
        userPassword = string
        sshKeyPublic = string
        passwordAuth = object({
          disable = bool
        })
      })
      extension = object({
        custom = object({
          enable   = bool
          name     = string
          fileName = string
          parameters = object({
            storageMounts = list(object({
              enable      = bool
              description = string
              type        = string
              path        = string
              source      = string
              options     = string
            }))
          })
        })
      })
    })
    network = object({
      acceleration = object({
        enable = bool
      })
    })
  })
}

locals {
  knfsdCache = merge(var.knfsdCache, {
    machine = merge(var.knfsdCache.machine, {
      image = merge(var.knfsdCache.machine.image, {
        publisher = var.knfsdCache.machine.image.publisher != "" ? var.knfsdCache.machine.image.publisher : module.global.linux.publisher
        product   = var.knfsdCache.machine.image.product != "" ? var.knfsdCache.machine.image.product : module.global.linux.offer
        name      = var.knfsdCache.machine.image.name != "" ? var.knfsdCache.machine.image.name : module.global.linux.sku
        version   = var.knfsdCache.machine.image.version != "" ? var.knfsdCache.machine.image.version : module.global.linux.version
      })
      adminLogin = merge(var.knfsdCache.machine.adminLogin, {
        userName     = var.knfsdCache.machine.adminLogin.userName != "" ? var.knfsdCache.machine.adminLogin.userName : data.azurerm_key_vault_secret.admin_username.value
        userPassword = var.knfsdCache.machine.adminLogin.userPassword != "" ? var.knfsdCache.machine.adminLogin.userPassword : data.azurerm_key_vault_secret.admin_password.value
        sshKeyPublic = var.knfsdCache.machine.adminLogin.sshKeyPublic != "" ? var.knfsdCache.machine.adminLogin.sshKeyPublic : data.azurerm_key_vault_secret.ssh_key_public.value
      })
    })
  })
}

#########################################################################
# Virtual Machines (https://learn.microsoft.com/azure/virtual-machines) #
#########################################################################

resource azurerm_network_interface cache {
  count               = var.knfsdCache.enable ? 1 : 0
  name                = var.knfsdCache.name
  resource_group_name = azurerm_resource_group.cache.name
  location            = azurerm_resource_group.cache.location
  ip_configuration {
    name                          = "ipConfig"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = data.azurerm_subnet.cache.id
  }
  accelerated_networking_enabled = var.knfsdCache.network.acceleration.enable
}

resource azurerm_linux_virtual_machine cache {
  count                           = var.knfsdCache.enable ? 1 : 0
  name                            = var.knfsdCache.name
  resource_group_name             = azurerm_resource_group.cache.name
  location                        = azurerm_resource_group.cache.location
  size                            = var.knfsdCache.machine.size
  admin_username                  = local.knfsdCache.machine.adminLogin.userName
  admin_password                  = local.knfsdCache.machine.adminLogin.userPassword
  disable_password_authentication = local.knfsdCache.machine.adminLogin.passwordAuth.disable
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  network_interface_ids = [
    azurerm_network_interface.cache[0].id
  ]
  os_disk {
    storage_account_type = var.knfsdCache.machine.osDisk.storageType
    caching              = var.knfsdCache.machine.osDisk.cachingType
    disk_size_gb         = var.knfsdCache.machine.osDisk.sizeGB > 0 ? var.knfsdCache.machine.osDisk.sizeGB : null
    dynamic diff_disk_settings {
      for_each = var.knfsdCache.machine.osDisk.ephemeral.enable ? [1] : []
      content {
        option    = "Local"
        placement = var.knfsdCache.machine.osDisk.ephemeral.placement
      }
    }
  }
  source_image_reference {
    publisher = local.knfsdCache.machine.image.publisher
    offer     = local.knfsdCache.machine.image.product
    sku       = local.knfsdCache.machine.image.name
    version   = local.knfsdCache.machine.image.version
  }
  plan {
    publisher = lower(local.knfsdCache.machine.image.publisher)
    product   = lower(local.knfsdCache.machine.image.product)
    name      = lower(local.knfsdCache.machine.image.name)
  }
  dynamic additional_capabilities {
    for_each = var.knfsdCache.machine.dataDisk.enable ? [1] : []
    content {
      ultra_ssd_enabled = lower(var.knfsdCache.machine.dataDisk.storageType) == "ultrassd_lrs"
    }
  }
  dynamic admin_ssh_key {
    for_each = local.knfsdCache.machine.adminLogin.sshKeyPublic != "" ? [1] : []
    content {
      username   = local.knfsdCache.machine.adminLogin.userName
      public_key = local.knfsdCache.machine.adminLogin.sshKeyPublic
    }
  }
}

resource azurerm_managed_disk cache {
  count                         = var.knfsdCache.enable && var.knfsdCache.machine.dataDisk.enable ? 1 : 0
  name                          = "${var.knfsdCache.name}_DataDisk_1"
  resource_group_name           = azurerm_resource_group.cache.name
  location                      = azurerm_resource_group.cache.location
  storage_account_type          = var.knfsdCache.machine.dataDisk.storageType
  disk_size_gb                  = var.knfsdCache.machine.dataDisk.sizeGB
  public_network_access_enabled = false
  create_option                 = "Empty"
}

resource azurerm_virtual_machine_data_disk_attachment data {
  count              = var.knfsdCache.enable && var.knfsdCache.machine.dataDisk.enable ? 1 : 0
  virtual_machine_id = azurerm_linux_virtual_machine.cache[0].id
  managed_disk_id    = azurerm_managed_disk.cache[0].id
  caching            = var.knfsdCache.machine.dataDisk.cachingType
  lun                = 0
}

resource azurerm_virtual_machine_extension cache {
  count                      = var.knfsdCache.enable && var.knfsdCache.machine.extension.custom.enable ? 1 : 0
  name                       = var.knfsdCache.machine.extension.custom.name
  type                       = "CustomScript"
  publisher                  = "Microsoft.Azure.Extensions"
  type_handler_version       = module.global.version.script_extension_linux
  automatic_upgrade_enabled  = false
  auto_upgrade_minor_version = true
  virtual_machine_id         = azurerm_linux_virtual_machine.cache[0].id
  protected_settings = jsonencode({
    script = base64encode(
      templatefile(var.knfsdCache.machine.extension.custom.fileName, var.knfsdCache.machine.extension.custom.parameters)
    )
  })
}

############################################################################
# Private DNS (https://learn.microsoft.com/azure/dns/private-dns-overview) #
############################################################################

resource azurerm_private_dns_a_record cache_knfsd {
  count               = var.knfsdCache.enable ? 1 : 0
  name                = var.dnsRecord.name
  resource_group_name = var.existingNetwork.enable ? var.existingNetwork.resourceGroupName : data.azurerm_private_dns_zone.studio.resource_group_name
  zone_name           = var.existingNetwork.enable ? var.existingNetwork.privateDns.zoneName : data.azurerm_private_dns_zone.studio.name
  records             = [azurerm_linux_virtual_machine.cache[0].private_ip_address]
  ttl                 = var.dnsRecord.ttlSeconds
}
