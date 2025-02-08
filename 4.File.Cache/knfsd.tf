variable knfsdCache {
  type = object({
    enable = bool
    cluster = object({
      name = string
      size = number
      node = object({
        name = string
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
              fileSystem = list(object({
                enable = bool
                mount = object({
                  type    = string
                  path    = string
                  target  = string
                  options = string
                })
              }))
            })
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
  count               = var.knfsdCache.enable ? 1 : 0
  name                = azurerm_linux_virtual_machine_scale_set.cache[0].name
  resource_group_name = azurerm_linux_virtual_machine_scale_set.cache[0].resource_group_name
}

locals {
  knfsdCache = merge(var.knfsdCache, {
    cluster = merge(var.knfsdCache.cluster, {
      node = merge(var.knfsdCache.cluster.node, {
        image = merge(var.knfsdCache.cluster.node.image, {
          publisher = var.knfsdCache.cluster.node.image.publisher != "" ? var.knfsdCache.cluster.node.image.publisher : module.global.linux.publisher
          product   = var.knfsdCache.cluster.node.image.product != "" ? var.knfsdCache.cluster.node.image.product : module.global.linux.offer
          name      = var.knfsdCache.cluster.node.image.name != "" ? var.knfsdCache.cluster.node.image.name : module.global.linux.sku
          version   = var.knfsdCache.cluster.node.image.version != "" ? var.knfsdCache.cluster.node.image.version : module.global.linux.version
        })
        adminLogin = merge(var.knfsdCache.cluster.node.adminLogin, {
          userName     = var.knfsdCache.cluster.node.adminLogin.userName != "" ? var.knfsdCache.cluster.node.adminLogin.userName : data.azurerm_key_vault_secret.admin_username.value
          userPassword = var.knfsdCache.cluster.node.adminLogin.userPassword != "" ? var.knfsdCache.cluster.node.adminLogin.userPassword : data.azurerm_key_vault_secret.admin_password.value
          sshKeyPublic = var.knfsdCache.cluster.node.adminLogin.sshKeyPublic != "" ? var.knfsdCache.cluster.node.adminLogin.sshKeyPublic : data.azurerm_key_vault_secret.ssh_key_public.value
        })
      })
    })
  })
}

######################################################################################################
# Virtual Machine Scale Sets (https://learn.microsoft.com/azure/virtual-machine-scale-sets/overview) #
######################################################################################################

resource azurerm_linux_virtual_machine_scale_set cache {
  count                           = var.knfsdCache.enable ? 1 : 0
  name                            = var.knfsdCache.cluster.name
  computer_name_prefix            = var.knfsdCache.cluster.node.name == "" ? null : var.knfsdCache.cluster.node.name
  resource_group_name             = azurerm_resource_group.cache.name
  location                        = azurerm_resource_group.cache.location
  sku                             = var.knfsdCache.cluster.node.size
  instances                       = var.knfsdCache.cluster.size
  admin_username                  = local.knfsdCache.cluster.node.adminLogin.userName
  admin_password                  = local.knfsdCache.cluster.node.adminLogin.userPassword
  disable_password_authentication = local.knfsdCache.cluster.node.adminLogin.passwordAuth.disable
  single_placement_group          = false
  overprovision                   = false
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
    enable_accelerated_networking = var.knfsdCache.network.acceleration.enable
  }
  os_disk {
    storage_account_type = var.knfsdCache.cluster.node.osDisk.storageType
    caching              = var.knfsdCache.cluster.node.osDisk.cachingType
    disk_size_gb         = var.knfsdCache.cluster.node.osDisk.sizeGB > 0 ? var.knfsdCache.cluster.node.osDisk.sizeGB : null
    dynamic diff_disk_settings {
      for_each = var.knfsdCache.cluster.node.osDisk.ephemeral.enable ? [1] : []
      content {
        option    = "Local"
        placement = var.knfsdCache.cluster.node.osDisk.ephemeral.placement
      }
    }
  }
  source_image_reference {
    publisher = local.knfsdCache.cluster.node.image.publisher
    offer     = local.knfsdCache.cluster.node.image.product
    sku       = local.knfsdCache.cluster.node.image.name
    version   = local.knfsdCache.cluster.node.image.version
  }
  plan {
    publisher = lower(local.knfsdCache.cluster.node.image.publisher)
    product   = lower(local.knfsdCache.cluster.node.image.product)
    name      = lower(local.knfsdCache.cluster.node.image.name)
  }
  dynamic extension {
    for_each = var.knfsdCache.cluster.node.extension.custom.enable ? [1] : []
    content {
      name                       = var.knfsdCache.cluster.node.extension.custom.name
      type                       = "CustomScript"
      publisher                  = "Microsoft.Azure.Extensions"
      type_handler_version       = module.global.version.script_extension_linux
      automatic_upgrade_enabled  = false
      auto_upgrade_minor_version = true
      protected_settings = jsonencode({
        script = base64encode(
          templatefile(var.knfsdCache.cluster.node.extension.custom.fileName, var.knfsdCache.cluster.node.extension.custom.parameters)
        )
      })
    }
  }
  dynamic admin_ssh_key {
    for_each = local.knfsdCache.cluster.node.adminLogin.sshKeyPublic != "" ? [1] : []
    content {
      username   = local.knfsdCache.cluster.node.adminLogin.userName
      public_key = local.knfsdCache.cluster.node.adminLogin.sshKeyPublic
    }
  }
}

############################################################################
# Private DNS (https://learn.microsoft.com/azure/dns/private-dns-overview) #
############################################################################

resource azurerm_private_dns_a_record cache_knfsd {
  count               = var.knfsdCache.enable ? 1 : 0
  name                = var.dnsRecord.name
  resource_group_name = var.existingNetwork.enable ? var.existingNetwork.resourceGroupName : data.azurerm_private_dns_zone.studio.resource_group_name
  zone_name           = var.existingNetwork.enable ? var.existingNetwork.privateDns.zoneName : data.azurerm_private_dns_zone.studio.name
  records             = data.azurerm_virtual_machine_scale_set.cache[0].instances[*].private_ip_address
  ttl                 = var.dnsRecord.ttlSeconds
}
