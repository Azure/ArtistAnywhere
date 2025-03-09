#################################################################################################################################################
# Active Directory (https://learn.microsoft.com/windows-server/identity/ad-ds/get-started/virtual-dc/active-directory-domain-services-overview) #
#################################################################################################################################################

variable activeDirectory {
  type = object({
    domainName = string
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
      })
    })
    network = object({
      acceleration = object({
        enable = bool
      })
      staticAddress = string
    })
  })
}

#########################################################################
# Virtual Machines (https://learn.microsoft.com/azure/virtual-machines) #
#########################################################################

resource azurerm_network_interface active_directory {
  name                = var.activeDirectory.machine.name
  resource_group_name = azurerm_resource_group.active_directory.name
  location            = azurerm_resource_group.active_directory.location
  ip_configuration {
    name                          = "ipConfig"
    private_ip_address_allocation = "Static"
    private_ip_address            = var.activeDirectory.network.staticAddress
    subnet_id                     = data.azurerm_subnet.identity.id
  }
  accelerated_networking_enabled = var.activeDirectory.network.acceleration.enable
}

 resource azurerm_windows_virtual_machine active_directory {
  name                = var.activeDirectory.machine.name
  resource_group_name = azurerm_resource_group.active_directory.name
  location            = azurerm_resource_group.active_directory.location
  size                = var.activeDirectory.machine.size
  admin_username      = local.activeDirectory.machine.adminLogin.userName
  admin_password      = local.activeDirectory.machine.adminLogin.userPassword
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  network_interface_ids = [
    azurerm_network_interface.active_directory.id
  ]
  os_disk {
    storage_account_type = var.activeDirectory.machine.osDisk.storageType
    caching              = var.activeDirectory.machine.osDisk.cachingMode
    disk_size_gb         = var.activeDirectory.machine.osDisk.sizeGB > 0 ? var.activeDirectory.machine.osDisk.sizeGB : null
  }
  source_image_reference {
    publisher = var.activeDirectory.machine.image.publisher
    offer     = var.activeDirectory.machine.image.product
    sku       = var.activeDirectory.machine.image.name
    version   = var.activeDirectory.machine.image.version
  }
}

resource azurerm_virtual_machine_extension active_directory {
  name                       = "Custom"
  type                       = "CustomScriptExtension"
  publisher                  = "Microsoft.Compute"
  type_handler_version       = module.core.version.script_extension_windows
  automatic_upgrade_enabled  = false
  auto_upgrade_minor_version = true
  virtual_machine_id         = azurerm_windows_virtual_machine.active_directory.id
  protected_settings = jsonencode({
    commandToExecute = "PowerShell -ExecutionPolicy Unrestricted -EncodedCommand ${textencodebase64(
      templatefile("cse.ps1", {
        activeDirectory = local.activeDirectory
        machineType     = "WinServer"
      }), "UTF-16LE"
    )}"
  })
}
