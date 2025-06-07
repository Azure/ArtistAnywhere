#########################################################################
# Virtual Machines (https://learn.microsoft.com/azure/virtual-machines) #
#########################################################################

variable dataLoad {
  type = object({
    mount = object({
      type    = string
      path    = string
      target  = string
      options = string
    })
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
        cachingMode = string
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
      adminLogin = merge(var.dataLoad.machine.adminLogin, {
        userName     = var.dataLoad.machine.adminLogin.userName != "" ? var.dataLoad.machine.adminLogin.userName : data.azurerm_key_vault_secret.admin_username.value
        userPassword = var.dataLoad.machine.adminLogin.userPassword != "" ? var.dataLoad.machine.adminLogin.userPassword : data.azurerm_key_vault_secret.admin_password.value
        sshKeyPublic = var.dataLoad.machine.adminLogin.sshKeyPublic != "" ? var.dataLoad.machine.adminLogin.sshKeyPublic : data.azurerm_key_vault_secret.ssh_key_public.value
      })
    })
  })
}

resource azurerm_network_interface storage_data_load {
  name                = var.dataLoad.machine.name
  resource_group_name = azurerm_resource_group.storage_data_load.name
  location            = azurerm_resource_group.storage_data_load.location
  ip_configuration {
    name                          = "ipConfig"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = data.azurerm_subnet.storage.id
  }
  accelerated_networking_enabled = var.dataLoad.network.acceleration.enable
}

 resource azurerm_linux_virtual_machine storage_data_load {
  name                            = var.dataLoad.machine.name
  resource_group_name             = azurerm_resource_group.storage_data_load.name
  location                        = azurerm_resource_group.storage_data_load.location
  size                            = var.dataLoad.machine.size
  admin_username                  = local.dataLoad.machine.adminLogin.userName
  admin_password                  = local.dataLoad.machine.adminLogin.userPassword
  disable_password_authentication = local.dataLoad.machine.adminLogin.passwordAuth.disable
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.main.id
    ]
  }
  network_interface_ids = [
    azurerm_network_interface.storage_data_load.id
  ]
  os_disk {
    storage_account_type = var.dataLoad.machine.osDisk.storageType
    caching              = var.dataLoad.machine.osDisk.cachingMode
    disk_size_gb         = var.dataLoad.machine.osDisk.sizeGB > 0 ? var.dataLoad.machine.osDisk.sizeGB : null
  }
  source_image_reference {
    publisher = local.dataLoad.machine.image.publisher
    offer     = local.dataLoad.machine.image.product
    sku       = local.dataLoad.machine.image.name
    version   = local.dataLoad.machine.image.version
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
  name                       = "DataLoad"
  type                       = "CustomScript"
  publisher                  = "Microsoft.Azure.Extensions"
  type_handler_version       = data.azurerm_app_configuration_keys.main.items[index(data.azurerm_app_configuration_keys.main.items[*].key, data.terraform_remote_state.foundation.outputs.appConfig.key.scriptExtensionLinux)].value
  automatic_upgrade_enabled  = false
  auto_upgrade_minor_version = true
  virtual_machine_id         = azurerm_linux_virtual_machine.storage_data_load.id
  protected_settings = jsonencode({
    script = base64encode(
      templatefile("cse.sh", {
        dataLoadMount = var.dataLoad.mount
      })
    )
  })
  timeouts {
    create = "90m"
  }
}
