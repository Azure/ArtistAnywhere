############################################################################################
# MySQL Flexible Server (https://learn.microsoft.com/azure/mysql/flexible-server/overview) #
############################################################################################

variable mySQL {
  type = object({
    enable  = bool
    name    = string
    type    = string
    version = string
    delegatedSubnet = object({
      enable = bool
    })
    authentication = object({
      activeDirectory = object({
        enable = bool
      })
    })
    storage = object({
      sizeGB = number
      iops   = number
      autoGrow = object({
        enabled = bool
      })
      ioScaling = object({
        enabled = bool
      })
    })
    backup = object({
      retentionDays = number
      geoRedundant = object({
        enable = bool
      })
      vault = object({
        enable     = bool
        name       = string
        type       = string
        redundancy = string
        softDelete = string
        retention = object({
          days = number
        })
        crossRegion = object({
          enable = bool
        })
      })
    })
    highAvailability = object({
      enable = bool
      mode   = string
    })
    maintenanceWindow = object({
      dayOfWeek = number
      start = object({
        hour   = number
        minute = number
      })
    })
    adminLogin = object({
      userName     = string
      userPassword = string
    })
    encryption = object({
      enable = bool
    })
    database = object({
      enable    = bool
      name      = string
      charset   = string
      collation = string
    })
  })
}

resource azurerm_mysql_flexible_server studio {
  count                        = var.mySQL.enable ? 1 : 0
  name                         = var.mySQL.name
  resource_group_name          = azurerm_resource_group.job_scheduler_mysql[0].name
  location                     = azurerm_resource_group.job_scheduler_mysql[0].location
  sku_name                     = var.mySQL.type
  version                      = var.mySQL.version
  backup_retention_days        = var.mySQL.backup.retentionDays
  geo_redundant_backup_enabled = var.mySQL.backup.geoRedundant.enable
  administrator_login          = var.mySQL.adminLogin.userName != "" ? var.mySQL.adminLogin.userName : data.azurerm_key_vault_secret.admin_username.value
  administrator_password       = var.mySQL.adminLogin.userPassword != "" ? var.mySQL.adminLogin.userPassword : data.azurerm_key_vault_secret.admin_password.value
  delegated_subnet_id          = var.mySQL.delegatedSubnet.enable ? data.azurerm_subnet.data_mysql[0].id : null
  private_dns_zone_id          = azurerm_private_dns_zone.mysql[0].id
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  storage {
    size_gb            = var.mySQL.storage.sizeGB
    iops               = var.mySQL.storage.ioScaling.enabled ? null : var.mySQL.storage.iops
    auto_grow_enabled  = var.mySQL.storage.autoGrow.enabled
    io_scaling_enabled = var.mySQL.storage.ioScaling.enabled
  }
  maintenance_window {
    day_of_week  = var.mySQL.maintenanceWindow.dayOfWeek
    start_hour   = var.mySQL.maintenanceWindow.start.hour
    start_minute = var.mySQL.maintenanceWindow.start.minute
  }
  dynamic high_availability {
    for_each = var.mySQL.highAvailability.enable ? [1] : []
    content {
      mode = var.mySQL.highAvailability.mode
    }
  }
  dynamic customer_managed_key {
    for_each = var.mySQL.encryption.enable ? [1] : []
    content {
      key_vault_key_id                     = data.azurerm_key_vault_key.data_encryption.id
      geo_backup_key_vault_key_id          = data.azurerm_key_vault_key.data_encryption.id
      primary_user_assigned_identity_id    = data.azurerm_user_assigned_identity.studio.id
      geo_backup_user_assigned_identity_id = data.azurerm_user_assigned_identity.studio.id
    }
  }
  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.mysql
  ]
}

resource azurerm_mysql_flexible_server_firewall_rule studio {
  count               = var.mySQL.enable && !var.mySQL.delegatedSubnet.enable ? 1 : 0
  name                = "AllowCurrentIP"
  resource_group_name = azurerm_resource_group.job_scheduler_mysql[0].name
  server_name         = azurerm_mysql_flexible_server.studio[0].name
  start_ip_address    = jsondecode(data.http.client_address.response_body).ip
  end_ip_address      = jsondecode(data.http.client_address.response_body).ip
}

resource azurerm_mysql_flexible_server_active_directory_administrator studio {
  count       = var.mySQL.enable && var.mySQL.authentication.activeDirectory.enable ? 1 : 0
  tenant_id   = data.azurerm_client_config.current.tenant_id
  server_id   = azurerm_mysql_flexible_server.studio[0].id
  identity_id = data.azuread_user.current.id
  object_id   = data.azuread_user.current.object_id
  login       = data.azuread_user.current.user_principal_name
}

resource azurerm_mysql_flexible_database studio {
  count               = var.mySQL.enable && var.mySQL.database.enable ? 1 : 0
  name                = var.mySQL.database.name
  resource_group_name = azurerm_resource_group.job_scheduler_mysql[0].name
  server_name         = azurerm_mysql_flexible_server.studio[0].name
  charset             = var.mySQL.database.charset
  collation           = var.mySQL.database.collation
}

###############################################################################################
# Private Endpoint (https://learn.microsoft.com/azure/private-link/private-endpoint-overview) #
###############################################################################################

resource azurerm_private_dns_zone mysql {
  count               = var.mySQL.enable ? 1 : 0
  name                = "privatelink.mysql.database.azure.com"
  resource_group_name = azurerm_resource_group.job_scheduler_mysql[0].name
}

resource azurerm_private_dns_zone_virtual_network_link mysql {
  count                 = var.mySQL.enable ? 1 : 0
  name                  = "mysql"
  resource_group_name   = azurerm_private_dns_zone.mysql[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.mysql[0].name
  virtual_network_id    = data.azurerm_virtual_network.studio.id
}

resource azurerm_private_endpoint mysql {
  count               = var.mySQL.enable && !var.mySQL.delegatedSubnet.enable ? 1 : 0
  name                = "${lower(azurerm_mysql_flexible_server.studio[0].name)}-${azurerm_private_dns_zone_virtual_network_link.mysql[0].name}"
  resource_group_name = azurerm_resource_group.job_scheduler_mysql[0].name
  location            = azurerm_resource_group.job_scheduler_mysql[0].location
  subnet_id           = data.azurerm_subnet.data.id
  private_service_connection {
    name                           = azurerm_mysql_flexible_server.studio[0].name
    private_connection_resource_id = azurerm_mysql_flexible_server.studio[0].id
    is_manual_connection           = false
    subresource_names = [
      "mySqlServer"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.mysql[0].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.mysql[0].id
    ]
  }
}

#################################################################################
# Backup Vault (https://learn.microsoft.com/azure/backup/backup-vault-overview) #
#################################################################################

resource azurerm_data_protection_backup_vault mysql {
  count                        = var.mySQL.enable && var.mySQL.backup.vault.enable ? 1 : 0
  name                         = var.mySQL.backup.vault.name
  resource_group_name          = azurerm_mysql_flexible_server.studio[0].resource_group_name
  location                     = azurerm_mysql_flexible_server.studio[0].location
  datastore_type               = var.mySQL.backup.vault.type
  redundancy                   = var.mySQL.backup.vault.redundancy
  soft_delete                  = var.mySQL.backup.vault.softDelete
  retention_duration_in_days   = var.mySQL.backup.vault.retention.days
  cross_region_restore_enabled = var.mySQL.backup.vault.crossRegion.enable
  identity {
    type = "SystemAssigned"
  }
}

output mySQL {
  value = var.mySQL.enable ? {
    fqdn     = azurerm_mysql_flexible_server.studio[0].fqdn
    public   = azurerm_mysql_flexible_server.studio[0].public_network_access_enabled
    database = var.mySQL.database.enable ? azurerm_mysql_flexible_database.studio[0].name : null
  } : null
}
