variable dataLoad {
  type = object({
    enable = bool
    source = object({
      accountName   = string
      containerName = string
      blobs = list(object({
        enable = bool
        name   = string
      }))
    })
    destination = string
    machine = object({
      name = string
      size = string
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
        type        = string
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
      acceleration = object({
        enable = bool
      })
    })
  })
}

locals {
  dataLoad = merge(var.dataLoad, {
    machine = merge(var.dataLoad.machine, {
      image = merge(var.dataLoad.machine.image, {
        plan = {
          publisher = try(data.terraform_remote_state.image.outputs.linuxPlan.publisher, var.dataLoad.machine.image.plan.publisher)
          product   = try(data.terraform_remote_state.image.outputs.linuxPlan.offer, var.dataLoad.machine.image.plan.product)
          name      = try(data.terraform_remote_state.image.outputs.linuxPlan.sku, var.dataLoad.machine.image.plan.name)
        }
      })
      adminLogin = merge(var.dataLoad.machine.adminLogin, {
        userName     = var.dataLoad.machine.adminLogin.userName != "" ? var.dataLoad.machine.adminLogin.userName : data.azurerm_key_vault_secret.admin_username.value
        userPassword = var.dataLoad.machine.adminLogin.userPassword != "" ? var.dataLoad.machine.adminLogin.userPassword : data.azurerm_key_vault_secret.admin_password.value
        sshKeyPublic = var.dataLoad.machine.adminLogin.sshKeyPublic != "" ? var.dataLoad.machine.adminLogin.sshKeyPublic : data.azurerm_key_vault_secret.ssh_key_public.value
      })
    })
  })
  fileSystemLinux = one([
    for fileSystem in module.global.fileSystems : fileSystem.linux if fileSystem.enable
  ])
}

resource azurerm_resource_group storage_data_load {
  count    = var.dataLoad.enable ? 1 : 0
  name     = "${var.resourceGroupName}.DataLoad"
  location = local.regionName
  tags = {
    AAA = basename(path.cwd)
  }
}

#########################################################################
# Virtual Machines (https://learn.microsoft.com/azure/virtual-machines) #
#########################################################################

resource azurerm_network_interface storage_data_load {
  count               = var.dataLoad.enable ? 1 : 0
  name                = var.dataLoad.machine.name
  resource_group_name = azurerm_resource_group.storage_data_load[0].name
  location            = azurerm_resource_group.storage_data_load[0].location
  ip_configuration {
    name                          = "ipConfig"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = data.azurerm_subnet.storage_region.id
  }
  accelerated_networking_enabled = var.dataLoad.network.acceleration.enable
  depends_on = [
    azurerm_storage_container.core
  ]
}

 resource azurerm_linux_virtual_machine storage_data_load {
  count                           = var.dataLoad.enable ? 1 : 0
  name                            = var.dataLoad.machine.name
  resource_group_name             = azurerm_resource_group.storage_data_load[0].name
  location                        = azurerm_resource_group.storage_data_load[0].location
  size                            = var.dataLoad.machine.size
  source_image_id                 = "/subscriptions/${data.azurerm_client_config.studio.subscription_id}/resourceGroups/${local.dataLoad.machine.image.resourceGroupName}/providers/Microsoft.Compute/galleries/${local.dataLoad.machine.image.galleryName}/images/${local.dataLoad.machine.image.definitionName}/versions/${local.dataLoad.machine.image.versionId}"
  admin_username                  = local.dataLoad.machine.adminLogin.userName
  admin_password                  = local.dataLoad.machine.adminLogin.userPassword
  disable_password_authentication = local.dataLoad.machine.adminLogin.passwordAuth.disable
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  network_interface_ids = [
    azurerm_network_interface.storage_data_load[0].id
  ]
  os_disk {
    storage_account_type = var.dataLoad.machine.osDisk.storageType
    caching              = var.dataLoad.machine.osDisk.cachingType
    disk_size_gb         = var.dataLoad.machine.osDisk.sizeGB > 0 ? var.dataLoad.machine.osDisk.sizeGB : null
  }
  dynamic plan {
    for_each = local.dataLoad.machine.image.plan.publisher != "" ? [1] : []
    content {
      publisher = local.dataLoad.machine.image.plan.publisher
      product   = local.dataLoad.machine.image.plan.product
      name      = local.dataLoad.machine.image.plan.name
    }
  }
  dynamic admin_ssh_key {
    for_each = local.dataLoad.machine.adminLogin.sshKeyPublic != "" ? [1] : []
    content {
      username   = local.dataLoad.machine.adminLogin.userName
      public_key = local.dataLoad.machine.adminLogin.sshKeyPublic
    }
  }
}

resource azurerm_virtual_machine_extension storage_data_load {
  count                      = var.dataLoad.enable ? 1 : 0
  name                       = "DataLoad"
  type                       = "CustomScript"
  publisher                  = "Microsoft.Azure.Extensions"
  type_handler_version       = "2.1"
  automatic_upgrade_enabled  = false
  auto_upgrade_minor_version = true
  virtual_machine_id         = azurerm_linux_virtual_machine.storage_data_load[0].id
  protected_settings = jsonencode({
    script = base64encode(
      templatefile("data.sh", {
        dataLoadSource      = var.dataLoad.source
        dataLoadDestination = var.dataLoad.destination
      })
    )
  })
  timeouts {
    create = "90m"
  }
}
