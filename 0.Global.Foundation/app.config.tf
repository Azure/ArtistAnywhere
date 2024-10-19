##########################################################################################
# App Configuration (https://learn.microsoft.com/azure/azure-app-configuration/overview) #
##########################################################################################

variable appConfig {
  type = object({
    tier = string
    localAuth = object({
      enable = bool
    })
    encryption = object({
      enable = bool
    })
  })
}

locals {
  appConfigStoreId = "/subscriptions/${data.azurerm_client_config.studio.subscription_id}/resourceGroups/${lower(azurerm_resource_group.studio.name)}/providers/Microsoft.AppConfiguration/configurationStores/${module.global.appConfig.name}"
}

resource azurerm_role_assignment studio_app_config_data_owner {
  role_definition_name = "App Configuration Data Owner" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/integration#app-configuration-data-owner
  principal_id         = data.azurerm_client_config.studio.object_id
  scope                = azurerm_app_configuration.studio.id
}

resource azurerm_role_assignment studio_app_config_data_reader {
  role_definition_name = "App Configuration Data Owner" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/integration#app-configuration-data-owner
  principal_id         = azurerm_user_assigned_identity.studio.principal_id
  scope                = azurerm_app_configuration.studio.id
}

resource time_sleep app_configuration_rbac {
  create_duration = "30s"
  depends_on = [
    azurerm_role_assignment.studio_app_config_data_owner,
    azurerm_role_assignment.studio_app_config_data_reader
  ]
}

resource azurerm_app_configuration studio {
  name                  = module.global.appConfig.name
  resource_group_name   = azurerm_resource_group.studio.name
  location              = azurerm_resource_group.studio.location
  sku                   = var.appConfig.tier
  local_auth_enabled    = var.appConfig.localAuth.enable
  public_network_access = "Enabled"
  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.studio.id
    ]
  }
  dynamic encryption {
    for_each = var.appConfig.encryption.enable ? [1] : []
    content {
      key_vault_key_identifier = azurerm_key_vault_key.studio[module.global.keyVault.keyName.dataEncryption].id
      identity_client_id       = azurerm_user_assigned_identity.studio.client_id
    }
  }
}

resource azurerm_app_configuration_key nvidia_cuda_version {
  configuration_store_id = local.appConfigStoreId
  key                    = module.global.appConfig.key.nvidiaCUDAVersion
  value                  = "12.6.2"
  depends_on = [
    time_sleep.app_configuration_rbac
  ]
}

resource azurerm_app_configuration_key nvidia_optix_version {
  configuration_store_id = local.appConfigStoreId
  key                    = module.global.appConfig.key.nvidiaOptiXVersion
  value                  = "8.0.0"
  depends_on = [
    time_sleep.app_configuration_rbac
  ]
}

resource azurerm_app_configuration_key az_blob_nfs_mount_version {
  configuration_store_id = local.appConfigStoreId
  key                    = module.global.appConfig.key.azBlobNFSMountVersion
  value                  = "2.0.9"
  depends_on = [
    time_sleep.app_configuration_rbac
  ]
}

resource azurerm_app_configuration_key hp_anyware_agent_version {
  configuration_store_id = local.appConfigStoreId
  key                    = module.global.appConfig.key.hpAnywareAgentVersion
  value                  = "24.07.3"
  depends_on = [
    time_sleep.app_configuration_rbac
  ]
}

resource azurerm_app_configuration_key job_scheduler_deadline_version {
  configuration_store_id = local.appConfigStoreId
  key                    = module.global.appConfig.key.jobSchedulerDeadlineVersion
  value                  = "10.3.2.1"
  depends_on = [
    time_sleep.app_configuration_rbac
  ]
}

resource azurerm_app_configuration_key job_scheduler_lsf_version {
  configuration_store_id = local.appConfigStoreId
  key                    = module.global.appConfig.key.jobSchedulerLSFVersion
  value                  = "10.2.0.12"
  depends_on = [
    time_sleep.app_configuration_rbac
  ]
}

resource azurerm_app_configuration_key job_processor_pbrt_version {
  configuration_store_id = local.appConfigStoreId
  key                    = module.global.appConfig.key.jobProcessorPBRTVersion
  value                  = "v4"
  depends_on = [
    time_sleep.app_configuration_rbac
  ]
}

resource azurerm_app_configuration_key job_processor_blender_version {
  configuration_store_id = local.appConfigStoreId
  key                    = module.global.appConfig.key.jobProcessorBlenderVersion
  value                  = "4.2.3"
  depends_on = [
    time_sleep.app_configuration_rbac
  ]
}

resource azurerm_app_configuration_key monitor_agent_linux_version {
  configuration_store_id = local.appConfigStoreId
  key                    = module.global.appConfig.key.monitorAgentLinuxVersion
  value                  = "1.33"
  depends_on = [
    time_sleep.app_configuration_rbac
  ]
}

resource azurerm_app_configuration_key monitor_agent_windows_version {
  configuration_store_id = local.appConfigStoreId
  key                    = module.global.appConfig.key.monitorAgentWindowsVersion
  value                  = "1.29"
  depends_on = [
    time_sleep.app_configuration_rbac
  ]
}
