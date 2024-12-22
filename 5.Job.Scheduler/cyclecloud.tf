######################################################################
# CycleCloud (https://learn.microsoft.com/azure/cyclecloud/overview) #
######################################################################

variable cycleCloud {
  type = object({
    enable = bool
    machine = object({
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
      })
      dataDisk = object({
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
    })
    network = object({
      subnetName = string
      acceleration = object({
        enable = bool
      })
      locationExtended = object({
        enable = bool
      })
    })
  })
}

locals {
  cycleCloud = merge(var.cycleCloud, {
    machine = merge(var.cycleCloud.machine, {
      adminLogin = merge(var.cycleCloud.machine.adminLogin, {
        userName     = var.cycleCloud.machine.adminLogin.userName != "" ? var.cycleCloud.machine.adminLogin.userName : data.azurerm_key_vault_secret.admin_username.value
        userPassword = var.cycleCloud.machine.adminLogin.userPassword != "" ? var.cycleCloud.machine.adminLogin.userPassword : data.azurerm_key_vault_secret.admin_password.value
        sshKeyPublic = var.cycleCloud.machine.adminLogin.sshKeyPublic != "" ? var.cycleCloud.machine.adminLogin.sshKeyPublic : data.azurerm_key_vault_secret.ssh_key_public.value
      })
    })
    network = merge(var.cycleCloud.network, {
      subnetId = "${var.cycleCloud.network.locationExtended.enable ? data.azurerm_virtual_network.studio_extended.id : data.azurerm_virtual_network.studio.id}/subnets/${var.existingNetwork.enable ? var.existingNetwork.subnetName : var.cycleCloud.network.subnetName}"
    })
  })
}

#########################################################################
# Virtual Machines (https://learn.microsoft.com/azure/virtual-machines) #
#########################################################################

resource azurerm_network_interface cycle_cloud {
  count               = var.cycleCloud.enable ? 1 : 0
  name                = var.cycleCloud.machine.name
  resource_group_name = azurerm_resource_group.job_scheduler.name
  location            = azurerm_resource_group.job_scheduler.location
  ip_configuration {
    name                          = "ipConfig"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = local.cycleCloud.network.subnetId
  }
  accelerated_networking_enabled = local.cycleCloud.network.acceleration.enable
}

# resource azurerm_managed_disk cycle_cloud {
#   count                         = var.cycleCloud.enable ? 1 : 0
#   name                          = var.cycleCloud.machine.name
#   resource_group_name           = azurerm_resource_group.job_scheduler.name
#   location                      = azurerm_resource_group.job_scheduler.location
#   storage_account_type          = var.cycleCloud.machine.dataDisk.storageType
#   disk_size_gb                  = var.cycleCloud.machine.dataDisk.sizeGB
#   public_network_access_enabled = false
#   create_option                 = "Empty"
# }

resource azurerm_linux_virtual_machine cycle_cloud {
  count                           = var.cycleCloud.enable ? 1 : 0
  name                            = var.cycleCloud.machine.name
  resource_group_name             = azurerm_resource_group.job_scheduler.name
  location                        = azurerm_resource_group.job_scheduler.location
  size                            = var.cycleCloud.machine.size
  admin_username                  = local.cycleCloud.machine.adminLogin.userName
  admin_password                  = local.cycleCloud.machine.adminLogin.userPassword
  disable_password_authentication = local.cycleCloud.machine.adminLogin.passwordAuth.disable
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  network_interface_ids = [
    azurerm_network_interface.cycle_cloud[0].id
  ]
  os_disk {
    storage_account_type = var.cycleCloud.machine.osDisk.storageType
    caching              = var.cycleCloud.machine.osDisk.cachingType
    disk_size_gb         = var.cycleCloud.machine.osDisk.sizeGB > 0 ? var.cycleCloud.machine.osDisk.sizeGB : null
  }
  source_image_reference {
    publisher = var.cycleCloud.machine.image.publisher
    offer     = var.cycleCloud.machine.image.product
    sku       = var.cycleCloud.machine.image.name
    version   = var.cycleCloud.machine.image.version
  }
  dynamic admin_ssh_key {
    for_each = local.cycleCloud.machine.adminLogin.sshKeyPublic != "" ? [1] : []
    content {
      username   = local.cycleCloud.machine.adminLogin.userName
      public_key = local.cycleCloud.machine.adminLogin.sshKeyPublic
    }
  }
}

# resource azurerm_virtual_machine_data_disk_attachment cycle_cloud {
#   count              = var.cycleCloud.enable ? 1 : 0
#   managed_disk_id    = azurerm_managed_disk.cycle_cloud[0].id
#   virtual_machine_id = azurerm_linux_virtual_machine.cycle_cloud[0].id
#   caching            = var.cycleCloud.machine.dataDisk.cachingType
#   lun                = 0
# }

resource azurerm_virtual_machine_extension cycle_cloud {
  count                      = var.cycleCloud.enable ? 1 : 0
  name                       = "Initialize"
  type                       = "CustomScript"
  publisher                  = "Microsoft.Azure.Extensions"
  type_handler_version       = module.global.version.script_extension_linux
  automatic_upgrade_enabled  = false
  auto_upgrade_minor_version = true
  virtual_machine_id         = azurerm_linux_virtual_machine.cycle_cloud[0].id
  protected_settings = jsonencode({
    script = base64encode(
      templatefile("cyclecloud.sh", {
      })
    )
  })
}
