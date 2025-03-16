##############################################################################################################
# PostgreSQL Flexible Server (https://learn.microsoft.com/azure/postgresql/flexible-server/service-overview) #
##############################################################################################################

variable postgreSQL {
  type = object({
    enable  = bool
    name    = string
    type    = string
    version = string
    delegatedSubnet = object({
      enable = bool
    })
    authentication = object({
      password = object({
        enable = bool
      })
      activeDirectory = object({
        enable = bool
      })
    })
    storage = object({
      type   = string
      sizeMB = number
      autoGrow = object({
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
      enable    = bool
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

resource azurerm_postgresql_flexible_server studio {
  count                         = var.postgreSQL.enable ? 1 : 0
  name                          = var.postgreSQL.name
  resource_group_name           = azurerm_resource_group.job_scheduler_sql.name
  location                      = azurerm_resource_group.job_scheduler_sql.location
  sku_name                      = var.postgreSQL.type
  version                       = var.postgreSQL.version
  backup_retention_days         = var.postgreSQL.backup.retentionDays
  geo_redundant_backup_enabled  = var.postgreSQL.backup.geoRedundant.enable
  administrator_login           = var.postgreSQL.adminLogin.userName != "" ? var.postgreSQL.adminLogin.userName : data.azurerm_key_vault_secret.admin_username.value
  administrator_password        = var.postgreSQL.adminLogin.userPassword != "" ? var.postgreSQL.adminLogin.userPassword : data.azurerm_key_vault_secret.admin_password.value
  delegated_subnet_id           = var.postgreSQL.delegatedSubnet.enable ? data.azurerm_subnet.data_postgresql[0].id : null
  public_network_access_enabled = !var.postgreSQL.delegatedSubnet.enable
  private_dns_zone_id           = azurerm_private_dns_zone.postgresql[0].id
  storage_tier                  = var.postgreSQL.storage.type
  storage_mb                    = var.postgreSQL.storage.sizeMB
  auto_grow_enabled             = var.postgreSQL.storage.autoGrow.enabled
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  authentication {
    tenant_id                     = var.postgreSQL.authentication.activeDirectory.enable ? data.azurerm_client_config.current.tenant_id : null
    password_auth_enabled         = var.postgreSQL.authentication.password.enable
    active_directory_auth_enabled = var.postgreSQL.authentication.activeDirectory.enable
  }
  dynamic maintenance_window {
    for_each = var.postgreSQL.maintenanceWindow.enable ? [1] : []
    content {
      day_of_week  = var.postgreSQL.maintenanceWindow.dayOfWeek
      start_hour   = var.postgreSQL.maintenanceWindow.start.hour
      start_minute = var.postgreSQL.maintenanceWindow.start.minute
    }
  }
  dynamic high_availability {
    for_each = var.postgreSQL.highAvailability.enable ? [1] : []
    content {
      mode = var.postgreSQL.highAvailability.mode
    }
  }
  dynamic customer_managed_key {
    for_each = var.postgreSQL.encryption.enable ? [1] : []
    content {
      key_vault_key_id                     = data.azurerm_key_vault_key.data_encryption.id
      geo_backup_key_vault_key_id          = data.azurerm_key_vault_key.data_encryption.id
      primary_user_assigned_identity_id    = data.azurerm_user_assigned_identity.studio.id
      geo_backup_user_assigned_identity_id = data.azurerm_user_assigned_identity.studio.id
    }
  }
  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.postgresql
  ]
  lifecycle {
    ignore_changes = [
      zone,
      high_availability[0].standby_availability_zone
    ]
  }
}

resource azurerm_postgresql_flexible_server_firewall_rule studio {
  count            = var.postgreSQL.enable && !var.postgreSQL.delegatedSubnet.enable ? 1 : 0
  name             = "AllowCurrentIP"
  server_id        = azurerm_postgresql_flexible_server.studio[0].id
  start_ip_address = jsondecode(data.http.client_address.response_body).ip
  end_ip_address   = jsondecode(data.http.client_address.response_body).ip
}

resource azurerm_postgresql_flexible_server_active_directory_administrator studio {
  count               = var.postgreSQL.enable && var.postgreSQL.authentication.activeDirectory.enable ? 1 : 0
  server_name         = azurerm_postgresql_flexible_server.studio[0].name
  resource_group_name = azurerm_postgresql_flexible_server.studio[0].resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  object_id           = data.azuread_user.current.object_id
  principal_name      = data.azuread_user.current.user_principal_name
  principal_type      = "ServicePrincipal"
}

resource azurerm_postgresql_database studio {
  count               = var.postgreSQL.enable && var.postgreSQL.database.enable ? 1 : 0
  name                = var.postgreSQL.database.name
  resource_group_name = azurerm_resource_group.job_scheduler_sql.name
  server_name         = azurerm_postgresql_flexible_server.studio[0].name
  charset             = var.postgreSQL.database.charset
  collation           = var.postgreSQL.database.collation
}

###############################################################################################
# Private Endpoint (https://learn.microsoft.com/azure/private-link/private-endpoint-overview) #
###############################################################################################

resource azurerm_private_dns_zone postgresql {
  count               = var.postgreSQL.enable ? 1 : 0
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.job_scheduler_sql.name
}

resource azurerm_private_dns_zone_virtual_network_link postgresql {
  count                 = var.postgreSQL.enable ? 1 : 0
  name                  = "postgresql"
  resource_group_name   = azurerm_private_dns_zone.postgresql[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.postgresql[0].name
  virtual_network_id    = data.azurerm_virtual_network.studio.id
}

resource azurerm_private_endpoint postgresql {
  count               = var.postgreSQL.enable && !var.postgreSQL.delegatedSubnet.enable ? 1 : 0
  name                = "${lower(azurerm_postgresql_flexible_server.studio[0].name)}-${azurerm_private_dns_zone_virtual_network_link.postgresql[0].name}"
  resource_group_name = azurerm_resource_group.job_scheduler_sql.name
  location            = azurerm_resource_group.job_scheduler_sql.location
  subnet_id           = data.azurerm_subnet.data.id
  private_service_connection {
    name                           = azurerm_postgresql_flexible_server.studio[0].name
    private_connection_resource_id = azurerm_postgresql_flexible_server.studio[0].id
    is_manual_connection           = false
    subresource_names = [
      "postgreSqlServer"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.postgresql[0].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.postgresql[0].id
    ]
  }
}

#################################################################################
# Backup Vault (https://learn.microsoft.com/azure/backup/backup-vault-overview) #
#################################################################################

resource azurerm_data_protection_backup_vault postgresql {
  count                        = var.postgreSQL.enable && var.postgreSQL.backup.vault.enable ? 1 : 0
  name                         = var.postgreSQL.backup.vault.name
  resource_group_name          = azurerm_postgresql_flexible_server.studio[0].resource_group_name
  location                     = azurerm_postgresql_flexible_server.studio[0].location
  datastore_type               = var.postgreSQL.backup.vault.type
  redundancy                   = var.postgreSQL.backup.vault.redundancy
  soft_delete                  = var.postgreSQL.backup.vault.softDelete
  retention_duration_in_days   = var.postgreSQL.backup.vault.retention.days
  cross_region_restore_enabled = var.postgreSQL.backup.vault.crossRegion.enable
  identity {
    type = "SystemAssigned"
  }
}

output postgreSQL {
  value = var.postgreSQL.enable ? {
    fqdn     = azurerm_postgresql_flexible_server.studio[0].fqdn
    public   = azurerm_postgresql_flexible_server.studio[0].public_network_access_enabled
    database = var.postgreSQL.database.enable ? azurerm_postgresql_database.studio[0].name : null
  } : null
}
