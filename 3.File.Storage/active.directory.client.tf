#################################################################################################################################################
# Active Directory (https://learn.microsoft.com/windows-server/identity/ad-ds/get-started/virtual-dc/active-directory-domain-services-overview) #
#################################################################################################################################################

variable activeDirectoryClient {
  type = object({
    enable      = bool
    domainName  = string
    serverName  = string
    orgUnitPath = string
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
      adminLogin = object({
        userName     = string
        userPassword = string
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
  activeDirectoryClient = merge(var.activeDirectoryClient, {
    machine = merge(var.activeDirectoryClient.machine, {
      adminLogin = merge(var.activeDirectoryClient.machine.adminLogin, {
        userName     = var.activeDirectoryClient.machine.adminLogin.userName != "" ? var.activeDirectoryClient.machine.adminLogin.userName : data.azurerm_key_vault_secret.admin_username.value
        userPassword = var.activeDirectoryClient.machine.adminLogin.userPassword != "" ? var.activeDirectoryClient.machine.adminLogin.userPassword : data.azurerm_key_vault_secret.admin_password.value
      })
    })
  })
}

#########################################################################
# Virtual Machines (https://learn.microsoft.com/azure/virtual-machines) #
#########################################################################

resource azurerm_network_interface active_directory_client {
  count               = var.activeDirectoryClient.enable ? 1 : 0
  name                = var.activeDirectoryClient.machine.name
  resource_group_name = azurerm_resource_group.active_directory[0].name
  location            = azurerm_resource_group.active_directory[0].location
  ip_configuration {
    name                          = "ipConfig"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = data.azurerm_subnet.identity.id
  }
  accelerated_networking_enabled = var.activeDirectoryClient.network.acceleration.enable
}

 resource azurerm_windows_virtual_machine active_directory_client {
  count               = var.activeDirectoryClient.enable ? 1 : 0
  name                = var.activeDirectoryClient.machine.name
  resource_group_name = azurerm_resource_group.active_directory[0].name
  location            = azurerm_resource_group.active_directory[0].location
  size                = var.activeDirectoryClient.machine.size
  admin_username      = local.activeDirectoryClient.machine.adminLogin.userName
  admin_password      = local.activeDirectoryClient.machine.adminLogin.userPassword
  custom_data         = base64encode(file("..\\0.Global.Foundation\\functions.ps1"))
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  network_interface_ids = [
    azurerm_network_interface.active_directory_client[0].id
  ]
  os_disk {
    storage_account_type = var.activeDirectoryClient.machine.osDisk.storageType
    caching              = var.activeDirectoryClient.machine.osDisk.cachingType
    disk_size_gb         = var.activeDirectoryClient.machine.osDisk.sizeGB > 0 ? var.activeDirectoryClient.machine.osDisk.sizeGB : null
  }
  source_image_reference {
    publisher = var.activeDirectoryClient.machine.image.publisher
    offer     = var.activeDirectoryClient.machine.image.product
    sku       = var.activeDirectoryClient.machine.image.name
    version   = var.activeDirectoryClient.machine.image.version
  }
  depends_on = [
    azurerm_virtual_machine_extension.active_directory
  ]
}

resource azurerm_virtual_machine_extension active_directory_client {
  count                      = var.activeDirectoryClient.enable ? 1 : 0
  name                       = "Custom"
  type                       = "CustomScriptExtension"
  publisher                  = "Microsoft.Compute"
  type_handler_version       = module.global.version.script_extension_windows
  automatic_upgrade_enabled  = false
  auto_upgrade_minor_version = true
  virtual_machine_id         = azurerm_windows_virtual_machine.active_directory_client[0].id
  protected_settings = jsonencode({
    commandToExecute = "PowerShell -ExecutionPolicy Unrestricted -EncodedCommand ${textencodebase64(
      templatefile("active.directory.client.ps1", {
        activeDirectoryClient = local.activeDirectoryClient
      }), "UTF-16LE"
    )}"
  })
}
