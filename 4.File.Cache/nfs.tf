######################################################################################################
# Virtual Machine Scale Sets (https://learn.microsoft.com/azure/virtual-machine-scale-sets/overview) #
######################################################################################################

variable nfsCache {
  type = object({
    enable = bool
    name   = string
    machine = object({
      size   = string
      count  = number
      prefix = string
      image = object({
        publisher = string
        product   = string
        name      = string
        version   = string
      })
      osDisk = object({
        storageType = string
        cachingMode = string
        sizeGB      = number
        ephemeral = object({
          enable    = bool
          placement = string
        })
      })
      dataDisk = object({
        enable      = bool
        storageType = string
        cachingMode = string
        sizeGB      = number
        count       = number
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

data azurerm_virtual_machine_scale_set cache {
  count               = var.nfsCache.enable ? 1 : 0
  name                = azurerm_orchestrated_virtual_machine_scale_set.cache[0].name
  resource_group_name = azurerm_orchestrated_virtual_machine_scale_set.cache[0].resource_group_name
}

locals {
  nfsCache = merge(var.nfsCache, {
    machine = merge(var.nfsCache.machine, {
      image = merge(var.nfsCache.machine.image, {
        publisher = var.nfsCache.machine.image.publisher != "" ? var.nfsCache.machine.image.publisher : module.core.image.linux.publisher
        product   = var.nfsCache.machine.image.product != "" ? var.nfsCache.machine.image.product : module.core.image.linux.offer
        name      = var.nfsCache.machine.image.name != "" ? var.nfsCache.machine.image.name : module.core.image.linux.sku
        version   = var.nfsCache.machine.image.version != "" ? var.nfsCache.machine.image.version : module.core.image.linux.version
      })
      adminLogin = merge(var.nfsCache.machine.adminLogin, {
        userName     = var.nfsCache.machine.adminLogin.userName != "" ? var.nfsCache.machine.adminLogin.userName : data.azurerm_key_vault_secret.admin_username.value
        userPassword = var.nfsCache.machine.adminLogin.userPassword != "" ? var.nfsCache.machine.adminLogin.userPassword : data.azurerm_key_vault_secret.admin_password.value
        sshKeyPublic = var.nfsCache.machine.adminLogin.sshKeyPublic != "" ? var.nfsCache.machine.adminLogin.sshKeyPublic : data.azurerm_key_vault_secret.ssh_key_public.value
      })
    })
  })
}

resource azurerm_orchestrated_virtual_machine_scale_set cache {
  count                       = var.nfsCache.enable ? 1 : 0
  name                        = var.nfsCache.name
  resource_group_name         = azurerm_resource_group.cache.name
  location                    = azurerm_resource_group.cache.location
  sku_name                    = var.nfsCache.machine.size
  instances                   = var.nfsCache.machine.count
  single_placement_group      = false
  platform_fault_domain_count = 1
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  network_interface {
    name    = "nic"
    primary = true
    ip_configuration {
      name      = "ipConfig"
      primary   = true
      subnet_id = data.azurerm_subnet.cache.id
    }
    enable_accelerated_networking = var.nfsCache.network.acceleration.enable
  }
  os_profile {
    linux_configuration {
      computer_name_prefix            = var.nfsCache.machine.prefix != "" ? var.nfsCache.machine.prefix : null
      admin_username                  = local.nfsCache.machine.adminLogin.userName
      admin_password                  = local.nfsCache.machine.adminLogin.userPassword
      disable_password_authentication = local.nfsCache.machine.adminLogin.passwordAuth.disable
      dynamic admin_ssh_key {
        for_each = local.nfsCache.machine.adminLogin.sshKeyPublic != "" ? [1] : []
        content {
          username   = local.nfsCache.machine.adminLogin.userName
          public_key = local.nfsCache.machine.adminLogin.sshKeyPublic
        }
      }
    }
  }
  os_disk {
    storage_account_type = var.nfsCache.machine.osDisk.storageType
    caching              = var.nfsCache.machine.osDisk.cachingMode
    disk_size_gb         = var.nfsCache.machine.osDisk.sizeGB > 0 ? var.nfsCache.machine.osDisk.sizeGB : null
    dynamic diff_disk_settings {
      for_each = var.nfsCache.machine.osDisk.ephemeral.enable ? [1] : []
      content {
        option    = "Local"
        placement = var.nfsCache.machine.osDisk.ephemeral.placement
      }
    }
  }
  source_image_reference {
    publisher = local.nfsCache.machine.image.publisher
    offer     = local.nfsCache.machine.image.product
    sku       = local.nfsCache.machine.image.name
    version   = local.nfsCache.machine.image.version
  }
  dynamic data_disk {
    for_each = var.nfsCache.machine.dataDisk.enable ? [1] : []
    content {
      storage_account_type = var.nfsCache.machine.dataDisk.storageType
      caching              = var.nfsCache.machine.dataDisk.cachingType
      disk_size_gb         = var.nfsCache.machine.dataDisk.sizeGB
      lun                  = 0
    }
  }
  dynamic additional_capabilities {
    for_each = var.nfsCache.machine.dataDisk.enable ? [1] : []
    content {
      ultra_ssd_enabled = lower(var.nfsCache.machine.dataDisk.storageType) == "ultrassd_lrs"
    }
  }
  dynamic extension {
    for_each = var.nfsCache.machine.extension.custom.enable ? [1] : []
    content {
      name                               = var.nfsCache.machine.extension.custom.name
      type                               = "CustomScript"
      publisher                          = "Microsoft.Azure.Extensions"
      type_handler_version               = module.core.version.script_extension_linux
      auto_upgrade_minor_version_enabled = true
      protected_settings = jsonencode({
        script = base64encode(
          templatefile(var.nfsCache.machine.extension.custom.fileName, merge(var.nfsCache.machine.extension.custom.parameters, {
            dataDiskCount = var.nfsCache.machine.dataDisk.count
          }))

        )
      })
    }
  }
}

############################################################################
# Private DNS (https://learn.microsoft.com/azure/dns/private-dns-overview) #
############################################################################

resource azurerm_private_dns_a_record cache_nfs {
  count               = var.nfsCache.enable ? 1 : 0
  name                = var.dnsRecord.name
  resource_group_name = var.existingNetwork.enable ? var.existingNetwork.resourceGroupName : data.azurerm_private_dns_zone.studio.resource_group_name
  zone_name           = var.existingNetwork.enable ? var.existingNetwork.privateDns.zoneName : data.azurerm_private_dns_zone.studio.name
  records             = data.azurerm_virtual_machine_scale_set.cache[0].instances[*].private_ip_address
  ttl                 = var.dnsRecord.ttlSeconds
}
