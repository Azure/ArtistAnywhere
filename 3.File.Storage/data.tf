variable dataLoad {
  type = object({
    enable  = bool
    targets = list(string)
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
        publisher = try(data.terraform_remote_state.image.outputs.linux.publisher, var.dataLoad.machine.image.publisher)
        product   = try(data.terraform_remote_state.image.outputs.linux.offer, var.dataLoad.machine.image.product)
        name      = try(data.terraform_remote_state.image.outputs.linux.sku, var.dataLoad.machine.image.name)
        version   = try(data.terraform_remote_state.image.outputs.linux.version, var.dataLoad.machine.image.version)
      })
      adminLogin = merge(var.dataLoad.machine.adminLogin, {
        userName     = var.dataLoad.machine.adminLogin.userName != "" ? var.dataLoad.machine.adminLogin.userName : data.azurerm_key_vault_secret.admin_username.value
        userPassword = var.dataLoad.machine.adminLogin.userPassword != "" ? var.dataLoad.machine.adminLogin.userPassword : data.azurerm_key_vault_secret.admin_password.value
        sshKeyPublic = var.dataLoad.machine.adminLogin.sshKeyPublic != "" ? var.dataLoad.machine.adminLogin.sshKeyPublic : data.azurerm_key_vault_secret.ssh_key_public.value
      })
    })
  })
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
    subnet_id                     = data.azurerm_subnet.storage.id
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
  source_image_reference {
    publisher = local.dataLoad.machine.image.publisher
    offer     = local.dataLoad.machine.image.product
    sku       = local.dataLoad.machine.image.name
    version   = local.dataLoad.machine.image.version
  }
  plan {
    publisher = lower(local.dataLoad.machine.image.publisher)
    product   = lower(local.dataLoad.machine.image.product)
    name      = lower(local.dataLoad.machine.image.name)
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
  type_handler_version       = module.global.version.script_extension_linux
  automatic_upgrade_enabled  = false
  auto_upgrade_minor_version = true
  virtual_machine_id         = azurerm_linux_virtual_machine.storage_data_load[0].id
  protected_settings = jsonencode({
    script = base64encode(
      templatefile("data.sh", {
        dataLoadTargets = var.dataLoad.targets
      })
    )
  })
  timeouts {
    create = "90m"
  }
}
