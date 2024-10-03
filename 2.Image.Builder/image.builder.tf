#############################################################################################
# Image Builder (https://learn.microsoft.com/azure/virtual-machines/image-builder-overview) #
#############################################################################################

variable imageBuilder {
  type = object({
    templates = list(object({
      enable = bool
      name   = string
      source = object({
        imageDefinition = object({
          name = string
        })
      })
      build = object({
        machineType    = string
        machineSize    = string
        gpuProvider    = string
        imageVersion   = string
        osDiskSizeGB   = number
        timeoutMinutes = number
        jobProcessors  = list(string)
      })
      distribute = object({
        replicaCount       = number
        storageAccountType = string
      })
      errorHandling = object({
        validationMode    = string
        customizationMode = string
      })
    }))
  })
}

variable imageCustomize {
  type = object({
    core = bool
    jobScheduler = object({
      deadline = bool
      slurm    = bool
    })
    jobProcessor = object({
      render = bool
      eda    = bool
    })
  })
}

variable binStorage {
  type = object({
    host = string
    auth = string
  })
  validation {
    condition     = var.binStorage.host != "" && var.binStorage.auth != ""
    error_message = "Missing required deployment configuration."
  }
}

locals {
  versionPath = {
    nvidiaCUDA           = one([for x in data.azurerm_app_configuration_keys.studio.items : x.value if x.key == module.global.appConfig.key.nvidiaCUDAVersion])
    nvidiaOptiX          = one([for x in data.azurerm_app_configuration_keys.studio.items : x.value if x.key == module.global.appConfig.key.nvidiaOptiXVersion])
    azBlobNFSMount       = one([for x in data.azurerm_app_configuration_keys.studio.items : x.value if x.key == module.global.appConfig.key.azBlobNFSMountVersion])
    hpAnywareAgent       = one([for x in data.azurerm_app_configuration_keys.studio.items : x.value if x.key == module.global.appConfig.key.hpAnywareAgentVersion])
    jobSchedulerDeadline = one([for x in data.azurerm_app_configuration_keys.studio.items : x.value if x.key == module.global.appConfig.key.jobSchedulerDeadlineVersion])
    jobSchedulerSlurm    = one([for x in data.azurerm_app_configuration_keys.studio.items : x.value if x.key == module.global.appConfig.key.jobSchedulerSlurmVersion])
    jobProcessorPBRT     = one([for x in data.azurerm_app_configuration_keys.studio.items : x.value if x.key == module.global.appConfig.key.jobProcessorPBRTVersion])
    jobProcessorBlender  = one([for x in data.azurerm_app_configuration_keys.studio.items : x.value if x.key == module.global.appConfig.key.jobProcessorBlenderVersion])
  }
  authCredential = {
    adminUsername   = data.azurerm_key_vault_secret.admin_username.value
    adminPassword   = data.azurerm_key_vault_secret.admin_password.value
    serviceUsername = data.azurerm_key_vault_secret.service_username.value
    servicePassword = data.azurerm_key_vault_secret.service_password.value
  }
}

resource azurerm_role_assignment managed_identity_operator {
  role_definition_name = "Managed Identity Operator" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/identity#managed-identity-operator
  principal_id         = data.azurerm_user_assigned_identity.studio.principal_id
  scope                = data.azurerm_user_assigned_identity.studio.id
}

resource azurerm_role_assignment virtual_machine_contributor {
  role_definition_name = "Virtual Machine Contributor" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/compute#virtual-machine-contributor
  principal_id         = data.azurerm_user_assigned_identity.studio.principal_id
  scope                = data.azurerm_resource_group.network.id
}

resource azurerm_role_assignment resource_group_contributor {
  role_definition_name = "Contributor" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/general#contributor
  principal_id         = data.azurerm_user_assigned_identity.studio.principal_id
  scope                = azurerm_resource_group.image.id
}

resource time_sleep image_builder_rbac {
  create_duration = "30s"
  depends_on = [
    azurerm_role_assignment.managed_identity_operator,
    azurerm_role_assignment.virtual_machine_contributor,
    azurerm_role_assignment.resource_group_contributor
  ]
}

resource azapi_resource linux {
  for_each = {
    for imageTemplate in var.imageBuilder.templates : imageTemplate.name => imageTemplate if var.computeGallery.platform.linux.enable && imageTemplate.enable && lower(imageTemplate.source.imageDefinition.name) == "linux"
  }
  name      = each.value.name
  type      = "Microsoft.VirtualMachineImages/imageTemplates@2024-02-01"
  parent_id = azurerm_resource_group.image.id
  location  = azurerm_resource_group.image.location
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  body = jsonencode({
    properties = {
      buildTimeoutInMinutes = each.value.build.timeoutMinutes
      vmProfile = {
        vmSize       = each.value.build.machineSize
        osDiskSizeGB = each.value.build.osDiskSizeGB
        userAssignedIdentities = [
          data.azurerm_user_assigned_identity.studio.id
        ]
        vnetConfig = {
          subnetId = data.azurerm_subnet.farm.id
        }
      }
      source = {
        type      = "PlatformImage"
        publisher = var.computeGallery.imageDefinitions[index(var.computeGallery.imageDefinitions.*.name, each.value.source.imageDefinition.name)].publisher
        offer     = var.computeGallery.imageDefinitions[index(var.computeGallery.imageDefinitions.*.name, each.value.source.imageDefinition.name)].offer
        sku       = var.computeGallery.imageDefinitions[index(var.computeGallery.imageDefinitions.*.name, each.value.source.imageDefinition.name)].sku
        version   = var.computeGallery.platform.linux.version
        planInfo = {
          planPublisher = lower(var.computeGallery.imageDefinitions[index(var.computeGallery.imageDefinitions.*.name, each.value.source.imageDefinition.name)].publisher)
          planProduct   = lower(var.computeGallery.imageDefinitions[index(var.computeGallery.imageDefinitions.*.name, each.value.source.imageDefinition.name)].offer)
          planName      = lower(var.computeGallery.imageDefinitions[index(var.computeGallery.imageDefinitions.*.name, each.value.source.imageDefinition.name)].sku)
        }
      }
      optimize = {
        vmBoot = {
          state = "Enabled"
        }
      }
      errorHandling = {
        onValidationError = each.value.errorHandling.validationMode
        onCustomizerError = each.value.errorHandling.customizationMode
      }
      customize = concat(
        [
          {
            type        = "File"
            sourceUri   = "https://raw.githubusercontent.com/Azure/ArtistAnywhere/main/0.Global.Foundation/functions.sh"
            destination = "/tmp/functions.sh"
          },
          {
            type        = "File"
            sourceUri   = "https://raw.githubusercontent.com/Azure/ArtistAnywhere/main/2.Image.Builder/Linux/customize.core.sh"
            destination = "/tmp/customize.core.sh"
          },
          {
            type        = "File"
            sourceUri   = "https://raw.githubusercontent.com/Azure/ArtistAnywhere/main/2.Image.Builder/Linux/customize.job.scheduler.deadline.sh"
            destination = "/tmp/customize.job.scheduler.deadline.sh"
          },
          {
            type        = "File"
            sourceUri   = "https://raw.githubusercontent.com/Azure/ArtistAnywhere/main/2.Image.Builder/Linux/customize.job.scheduler.slurm.sh"
            destination = "/tmp/customize.job.scheduler.slurm.sh"
          },
          {
            type        = "File"
            sourceUri   = "https://raw.githubusercontent.com/Azure/ArtistAnywhere/main/2.Image.Builder/Linux/customize.job.processor.sh"
            destination = "/tmp/customize.job.processor.sh"
          },
          {
            type        = "File"
            sourceUri   = "https://raw.githubusercontent.com/Azure/ArtistAnywhere/main/2.Image.Builder/Linux/terminate.sh"
            destination = "/tmp/terminate.sh"
          }
        ],
        [
          {
            type = "Shell"
            inline = [
              "dnf -y install nfs-utils",
              "if [ ${each.value.build.machineType} == JobScheduler ]; then",
              "  echo 'Customize (Start): NFS Server'",
              "  systemctl --now enable nfs-server",
              "  echo 'Customize (End): NFS Server'",
              "fi",
              "hostname ${each.value.name}"
            ]
          },
          {
            type = "Shell"
            inline = [
              "if [ ${var.imageCustomize.core} == true ]; then",
              "  cat /tmp/customize.core.sh | tr -d \r | buildConfigEncoded=${base64encode(jsonencode(merge(each.value.build, {versionPath = local.versionPath}, {authCredential = local.authCredential}, {binStorage = var.binStorage})))} /bin/bash",
              "fi",
              "if [ ${var.imageCustomize.jobScheduler.deadline} == true ]; then",
              "  cat /tmp/customize.job.scheduler.deadline.sh | tr -d \r | buildConfigEncoded=${base64encode(jsonencode(merge(each.value.build, {versionPath = local.versionPath}, {authCredential = local.authCredential}, {binStorage = var.binStorage})))} /bin/bash",
              "fi",
              "if [ ${var.imageCustomize.jobScheduler.slurm} == true ]; then",
              "  cat /tmp/customize.job.scheduler.slurm.sh | tr -d \r | buildConfigEncoded=${base64encode(jsonencode(merge(each.value.build, {versionPath = local.versionPath}, {authCredential = local.authCredential}, {binStorage = var.binStorage})))} /bin/bash",
              "fi",
              "if [ ${var.imageCustomize.jobProcessor.render} == true ]; then",
              "  cat /tmp/customize.job.processor.render.sh | tr -d \r | buildConfigEncoded=${base64encode(jsonencode(merge(each.value.build, {versionPath = local.versionPath}, {authCredential = local.authCredential}, {binStorage = var.binStorage})))} /bin/bash",
              "fi",
              "if [ ${var.imageCustomize.jobProcessor.eda} == true ]; then",
              "  cat /tmp/customize.job.processor.eda.sh | tr -d \r | buildConfigEncoded=${base64encode(jsonencode(merge(each.value.build, {versionPath = local.versionPath}, {authCredential = local.authCredential}, {binStorage = var.binStorage})))} /bin/bash",
              "fi"
            ]
          }
        ]
      )
      distribute = [
        {
          type           = "SharedImage"
          runOutputName  = "${each.value.name}-${each.value.build.imageVersion}"
          galleryImageId = "${azurerm_shared_image.studio[each.value.source.imageDefinition.name].id}/versions/${each.value.build.imageVersion}"
          targetRegions = [
            for regionName in local.regionNames : merge(each.value.distribute, {
              name = regionName
            })
          ]
          versioning = {
            scheme = "Latest"
            major  = tonumber(split(".", each.value.build.imageVersion)[0])
          }
          artifactTags = {
            imageTemplateName = each.value.name
          }
        }
      ]
    }
  })
  schema_validation_enabled = false
  lifecycle {
    ignore_changes = [
      body
    ]
  }
  depends_on = [
    time_sleep.image_builder_rbac
  ]
}

resource azapi_resource windows {
  for_each = {
    for imageTemplate in var.imageBuilder.templates : imageTemplate.name => imageTemplate if var.computeGallery.platform.windows.enable && imageTemplate.enable && startswith(imageTemplate.source.imageDefinition.name, "Win")
  }
  name      = each.value.name
  type      = "Microsoft.VirtualMachineImages/imageTemplates@2024-02-01"
  parent_id = azurerm_resource_group.image.id
  location  = azurerm_resource_group.image.location
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  body = jsonencode({
    properties = {
      buildTimeoutInMinutes = each.value.build.timeoutMinutes
      vmProfile = {
        vmSize       = each.value.build.machineSize
        osDiskSizeGB = each.value.build.osDiskSizeGB
        userAssignedIdentities = [
          data.azurerm_user_assigned_identity.studio.id
        ]
        vnetConfig = {
          subnetId = data.azurerm_subnet.farm.id
        }
      }
      source = {
        type      = "PlatformImage"
        publisher = var.computeGallery.imageDefinitions[index(var.computeGallery.imageDefinitions.*.name, each.value.source.imageDefinition.name)].publisher
        offer     = var.computeGallery.imageDefinitions[index(var.computeGallery.imageDefinitions.*.name, each.value.source.imageDefinition.name)].offer
        sku       = var.computeGallery.imageDefinitions[index(var.computeGallery.imageDefinitions.*.name, each.value.source.imageDefinition.name)].sku
        version   = var.computeGallery.platform.windows.version
      }
      optimize = {
        vmBoot = {
          state = "Enabled"
        }
      }
      errorHandling = {
        onValidationError = each.value.errorHandling.validationMode
        onCustomizerError = each.value.errorHandling.customizationMode
      }
      customize = concat(
        [
          {
            type        = "File"
            sourceUri   = "https://raw.githubusercontent.com/Azure/ArtistAnywhere/main/0.Global.Foundation/functions.ps1"
            destination = "C:\\AzureData\\functions.ps1"
          },
          {
            type        = "File"
            sourceUri   = "https://raw.githubusercontent.com/Azure/ArtistAnywhere/main/2.Image.Builder/Windows/customize.core.ps1"
            destination = "C:\\AzureData\\customize.core.ps1"
          },
          {
            type        = "File"
            sourceUri   = "https://raw.githubusercontent.com/Azure/ArtistAnywhere/main/2.Image.Builder/Windows/customize.job.scheduler.deadline.ps1"
            destination = "C:\\AzureData\\customize.job.scheduler.deadline.ps1"
          },
          {
            type        = "File"
            sourceUri   = "https://raw.githubusercontent.com/Azure/ArtistAnywhere/main/2.Image.Builder/Windows/customize.job.scheduler.slurm.ps1"
            destination = "C:\\AzureData\\customize.job.scheduler.slurm.ps1"
          },
          {
            type        = "File"
            sourceUri   = "https://raw.githubusercontent.com/Azure/ArtistAnywhere/main/2.Image.Builder/Windows/customize.job.processor.ps1"
            destination = "C:\\AzureData\\customize.job.processor.ps1"
          },
          {
            type        = "File"
            sourceUri   = "https://raw.githubusercontent.com/Azure/ArtistAnywhere/main/2.Image.Builder/Windows/terminate.ps1"
            destination = "C:\\AzureData\\terminate.ps1"
          }
        ],
        [
          {
            type = "PowerShell"
            inline = [
              "if ('${each.value.build.machineType}' -eq 'JobScheduler') {",
                "Write-Host 'Customize (Start): NFS Server'",
                "Install-WindowsFeature -Name 'FS-NFS-Service'",
                "Write-Host 'Customize (End): NFS Server'",
                "Write-Host 'Customize (Start): AD Domain Services'",
                "Install-WindowsFeature -Name 'AD-Domain-Services' -IncludeManagementTools",
                "Write-Host 'Customize (End): AD Domain Services'",
              "}",
              "Rename-Computer -NewName ${each.value.name}"
            ]
          },
          {
            type = "WindowsRestart"
          },
          {
            type = "PowerShell"
            inline = [
              "if ('${var.imageCustomize.core}' -eq $true) {",
              "  C:\\AzureData\\customize.core.ps1 -buildConfigEncoded ${base64encode(jsonencode(merge(each.value.build, {versionPath = local.versionPath}, {authCredential = local.authCredential}, {binStorage = var.binStorage})))}",
              "}",
              "if ('${var.imageCustomize.jobScheduler.deadline}' -eq $true) {",
              "  C:\\AzureData\\customize.job.scheduler.deadline.ps1 -buildConfigEncoded ${base64encode(jsonencode(merge(each.value.build, {versionPath = local.versionPath}, {authCredential = local.authCredential}, {binStorage = var.binStorage})))}",
              "}",
              "if ('${var.imageCustomize.jobProcessor.render}' -eq $true) {",
              "  C:\\AzureData\\customize.job.processor.render.ps1 -buildConfigEncoded ${base64encode(jsonencode(merge(each.value.build, {versionPath = local.versionPath}, {authCredential = local.authCredential}, {binStorage = var.binStorage})))}",
              "}"
            ]
            runElevated = true
            runAsSystem = true
          },
          {
            type = "WindowsRestart"
          }
        ]
      )
      distribute = [
        {
          type           = "SharedImage"
          runOutputName  = "${each.value.name}-${each.value.build.imageVersion}"
          galleryImageId = "${azurerm_shared_image.studio[each.value.source.imageDefinition.name].id}/versions/${each.value.build.imageVersion}"
          targetRegions = [
            for regionName in local.regionNames : merge(each.value.distribute, {
              name = regionName
            })
          ]
          versioning = {
            scheme = "Latest"
            major  = tonumber(split(".", each.value.build.imageVersion)[0])
          }
          artifactTags = {
            imageTemplateName = each.value.name
          }
        }
      ]
    }
  })
  schema_validation_enabled = false
  lifecycle {
    ignore_changes = [
      body
    ]
  }
  depends_on = [
    time_sleep.image_builder_rbac
  ]
}
