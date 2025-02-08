variable knfsd {
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

locals {
  knfsd = merge(var.knfsd, {
    cluster = merge(var.knfsd.cluster, {
      node = merge(var.knfsd.cluster.node, {
        image = merge(var.knfsd.cluster.node.image, {
          publisher = var.knfsd.cluster.node.image.publisher != "" ? var.knfsd.cluster.node.image.publisher : module.global.linux.publisher
          product   = var.knfsd.cluster.node.image.product != "" ? var.knfsd.cluster.node.image.product : module.global.linux.offer
          name      = var.knfsd.cluster.node.image.name != "" ? var.knfsd.cluster.node.image.name : module.global.linux.sku
          version   = var.knfsd.cluster.node.image.version != "" ? var.knfsd.cluster.node.image.version : module.global.linux.version
        })
        adminLogin = merge(var.knfsd.cluster.node.adminLogin, {
          userName     = var.knfsd.cluster.node.adminLogin.userName != "" ? var.knfsd.cluster.node.adminLogin.userName : data.azurerm_key_vault_secret.admin_username.value
          userPassword = var.knfsd.cluster.node.adminLogin.userPassword != "" ? var.knfsd.cluster.node.adminLogin.userPassword : data.azurerm_key_vault_secret.admin_password.value
          sshKeyPublic = var.knfsd.cluster.node.adminLogin.sshKeyPublic != "" ? var.knfsd.cluster.node.adminLogin.sshKeyPublic : data.azurerm_key_vault_secret.ssh_key_public.value
        })
      })
    })
  })
}

######################################################################################################
# Virtual Machine Scale Sets (https://learn.microsoft.com/azure/virtual-machine-scale-sets/overview) #
######################################################################################################

resource azurerm_linux_virtual_machine_scale_set cache {
  count                           = var.knfsd.enable ? 1 : 0
  name                            = var.knfsd.cluster.name
  computer_name_prefix            = var.knfsd.cluster.node.name == "" ? null : var.knfsd.cluster.node.name
  resource_group_name             = azurerm_resource_group.cache.name
  location                        = azurerm_resource_group.cache.location
  sku                             = var.knfsd.cluster.node.size
  instances                       = var.knfsd.cluster.size
  admin_username                  = local.knfsd.cluster.node.adminLogin.userName
  admin_password                  = local.knfsd.cluster.node.adminLogin.userPassword
  disable_password_authentication = local.knfsd.cluster.node.adminLogin.passwordAuth.disable
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
    enable_accelerated_networking = var.knfsd.network.acceleration.enable
  }
  os_disk {
    storage_account_type = var.knfsd.cluster.node.osDisk.storageType
    caching              = var.knfsd.cluster.node.osDisk.cachingType
    disk_size_gb         = var.knfsd.cluster.node.osDisk.sizeGB > 0 ? var.knfsd.cluster.node.osDisk.sizeGB : null
    dynamic diff_disk_settings {
      for_each = var.knfsd.cluster.node.osDisk.ephemeral.enable ? [1] : []
      content {
        option    = "Local"
        placement = var.knfsd.cluster.node.osDisk.ephemeral.placement
      }
    }
  }
  source_image_reference {
    publisher = local.knfsd.cluster.node.image.publisher
    offer     = local.knfsd.cluster.node.image.product
    sku       = local.knfsd.cluster.node.image.name
    version   = local.knfsd.cluster.node.image.version
  }
  plan {
    publisher = lower(local.knfsd.cluster.node.image.publisher)
    product   = lower(local.knfsd.cluster.node.image.product)
    name      = lower(local.knfsd.cluster.node.image.name)
  }
  dynamic extension {
    for_each = var.knfsd.cluster.node.extension.custom.enable ? [1] : []
    content {
      name                       = var.knfsd.cluster.node.extension.custom.name
      type                       = "CustomScript"
      publisher                  = "Microsoft.Azure.Extensions"
      type_handler_version       = module.global.version.script_extension_linux
      automatic_upgrade_enabled  = false
      auto_upgrade_minor_version = true
      protected_settings = jsonencode({
        script = base64encode(
          templatefile(var.knfsd.cluster.node.extension.custom.fileName, var.knfsd.cluster.node.extension.custom.parameters)
        )
      })
    }
  }
  dynamic admin_ssh_key {
    for_each = local.knfsd.cluster.node.adminLogin.sshKeyPublic != "" ? [1] : []
    content {
      username   = local.knfsd.cluster.node.adminLogin.userName
      public_key = local.knfsd.cluster.node.adminLogin.sshKeyPublic
    }
  }
}
