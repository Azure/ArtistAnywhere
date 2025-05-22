##################################################################################################
# Application Configuration (https://learn.microsoft.com/azure/azure-app-configuration/overview) #
##################################################################################################

variable appConfig {
  type = object({
    name = string
    type = string
  })
}

locals {
  appConfigKey = {
    scriptExtensionLinux   = "scriptExtensionLinux"
    scriptExtensionWindows = "scriptExtensionWindows"
    jobManagerSlurm        = "jobManagerSlurm"
    jobManagerDeadline     = "jobManagerDeadline"
    jobProcessorPBRT       = "jobProcessorPBRT"
    jobProcessorBlender    = "jobProcessorBlender"
    nvidiaCUDAWindows      = "nvidiaCUDAWindows"
    hpAnywareAgent         = "hpAnywareAgent"
  }
}

resource azurerm_role_assignment app_config_data_owner {
  role_definition_name = "App Configuration Data Owner" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/integration#app-configuration-data-owner
  principal_id         = data.azurerm_client_config.current.object_id
  scope                = azurerm_app_configuration.main.id
}

resource time_sleep app_config_rbac {
  create_duration = "30s"
  depends_on = [
    azurerm_role_assignment.app_config_data_owner
  ]
}

resource azurerm_app_configuration main {
  name                                             = var.appConfig.name
  resource_group_name                              = azurerm_resource_group.foundation.name
  location                                         = azurerm_resource_group.foundation.location
  sku                                              = var.appConfig.type
  data_plane_proxy_authentication_mode             = "Pass-through"
  data_plane_proxy_private_link_delegation_enabled = true
  local_auth_enabled                               = false
  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.main.id
    ]
  }
}

resource azurerm_app_configuration_key script_extension_linux {
  configuration_store_id = azurerm_app_configuration.main.id
  key                    = local.appConfigKey.scriptExtensionLinux
  label                  = "Script Extension Linux"
  value                  = "2.1"
  content_type           = "kv"
  depends_on = [
    time_sleep.app_config_rbac
  ]
}

resource azurerm_app_configuration_key script_extension_windows {
  configuration_store_id = azurerm_app_configuration.main.id
  key                    = local.appConfigKey.scriptExtensionWindows
  label                  = "Script Extension Windows"
  value                  = "1.10"
  content_type           = "kv"
  depends_on = [
    time_sleep.app_config_rbac
  ]
}

resource azurerm_app_configuration_key job_manager_slurm {
  configuration_store_id = azurerm_app_configuration.main.id
  key                    = local.appConfigKey.jobManagerSlurm
  label                  = "Job Manager Slurm"
  value                  = "24.11.5"
  content_type           = "kv"
  depends_on = [
    time_sleep.app_config_rbac
  ]
}

resource azurerm_app_configuration_key job_manager_deadline {
  configuration_store_id = azurerm_app_configuration.main.id
  key                    = local.appConfigKey.jobManagerDeadline
  label                  = "Job Manager Deadline"
  value                  = "10.4.0.13"
  content_type           = "kv"
  depends_on = [
    time_sleep.app_config_rbac
  ]
}

resource azurerm_app_configuration_key job_processor_pbrt {
  configuration_store_id = azurerm_app_configuration.main.id
  key                    = local.appConfigKey.jobProcessorPBRT
  label                  = "Job Processor PBRT"
  value                  = "v4"
  content_type           = "kv"
  depends_on = [
    time_sleep.app_config_rbac
  ]
}

resource azurerm_app_configuration_key job_processor_blender {
  configuration_store_id = azurerm_app_configuration.main.id
  key                    = local.appConfigKey.jobProcessorBlender
  label                  = "Job Processor Blender"
  value                  = "4.4.3"
  content_type           = "kv"
  depends_on = [
    time_sleep.app_config_rbac
  ]
}

resource azurerm_app_configuration_key nvidia_cuda_windows {
  configuration_store_id = azurerm_app_configuration.main.id
  key                    = local.appConfigKey.nvidiaCUDAWindows
  label                  = "NVIDIA CUDA Windows"
  value                  = "12.9.0"
  content_type           = "kv"
  depends_on = [
    time_sleep.app_config_rbac
  ]
}

resource azurerm_app_configuration_key hp_anyware_agent {
  configuration_store_id = azurerm_app_configuration.main.id
  key                    = local.appConfigKey.hpAnywareAgent
  label                  = "HP Anyware Agent"
  value                  = "24.10.2"
  content_type           = "kv"
  depends_on = [
    time_sleep.app_config_rbac
  ]
}

output appConfig {
  value = {
    id   = azurerm_app_configuration.main.id
    name = azurerm_app_configuration.main.name
    key  = local.appConfigKey
  }
}
