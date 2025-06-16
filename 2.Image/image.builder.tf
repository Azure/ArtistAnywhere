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
        jobManagers    = list(string)
        jobProcessors  = list(string)
      })
    }))
    distribute = object({
      replicaCount   = number
      replicaRegions = list(string)
      storageAccount = object({
        type = string
      })
    })
    errorHandling = object({
      validationMode    = string
      customizationMode = string
    })
  })
}

locals {
  blobStorage = merge(data.terraform_remote_state.foundation.outputs.storage.blob, {
    authTokenUrl = "${data.terraform_remote_state.foundation.outputs.storage.blob.authTokenUrl}&msi_res_id=${data.azurerm_user_assigned_identity.main.id}"
  })
  appVersion = {
    jobManagerSlurm     = data.azurerm_app_configuration_keys.main.items[index(data.azurerm_app_configuration_keys.main.items[*].key, data.terraform_remote_state.foundation.outputs.appConfig.key.jobManagerSlurm)].value
    jobManagerDeadline  = data.azurerm_app_configuration_keys.main.items[index(data.azurerm_app_configuration_keys.main.items[*].key, data.terraform_remote_state.foundation.outputs.appConfig.key.jobManagerDeadline)].value
    jobProcessorPBRT    = data.azurerm_app_configuration_keys.main.items[index(data.azurerm_app_configuration_keys.main.items[*].key, data.terraform_remote_state.foundation.outputs.appConfig.key.jobProcessorPBRT)].value
    jobProcessorBlender = data.azurerm_app_configuration_keys.main.items[index(data.azurerm_app_configuration_keys.main.items[*].key, data.terraform_remote_state.foundation.outputs.appConfig.key.jobProcessorBlender)].value
    nvidiaCUDAWindows   = data.azurerm_app_configuration_keys.main.items[index(data.azurerm_app_configuration_keys.main.items[*].key, data.terraform_remote_state.foundation.outputs.appConfig.key.nvidiaCUDAWindows)].value
    hpAnywareAgent      = data.azurerm_app_configuration_keys.main.items[index(data.azurerm_app_configuration_keys.main.items[*].key, data.terraform_remote_state.foundation.outputs.appConfig.key.hpAnywareAgent)].value
  }
  authCredential = {
    adminUsername   = data.azurerm_key_vault_secret.admin_username.value
    adminPassword   = data.azurerm_key_vault_secret.admin_password.value
    serviceUsername = data.azurerm_key_vault_secret.service_username.value
    servicePassword = data.azurerm_key_vault_secret.service_password.value
  }
}

resource azurerm_role_assignment compute_gallery_artifacts_publisher {
  role_definition_name = "Compute Gallery Artifacts Publisher" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/compute#compute-gallery-artifacts-publisher
  principal_id         = data.azurerm_user_assigned_identity.main.principal_id
  scope                = azurerm_resource_group.image_gallery.id
}

resource time_sleep image_builder_rbac {
  create_duration = "30s"
  depends_on = [
    azurerm_role_assignment.compute_gallery_artifacts_publisher
  ]
}

resource azapi_resource linux {
  for_each = {
    for imageTemplate in var.imageBuilder.templates : imageTemplate.name => imageTemplate if imageTemplate.enable && strcontains(lower(imageTemplate.source.imageDefinition.name), "lnx")
  }
  name      = each.value.name
  type      = "Microsoft.VirtualMachineImages/imageTemplates@2024-02-01"
  parent_id = azurerm_resource_group.image_builder.id
  location  = azurerm_resource_group.image_builder.location
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.main.id
    ]
  }
  body = {
    properties = {
      buildTimeoutInMinutes = each.value.build.timeoutMinutes
      vmProfile = {
        vmSize       = each.value.build.machineSize
        osDiskSizeGB = each.value.build.osDiskSizeGB
        userAssignedIdentities = [
          data.azurerm_user_assigned_identity.main.id
        ]
        vnetConfig = {
          subnetId = data.azurerm_subnet.main.id
        }
      }
      source = {
        type      = "PlatformImage"
        publisher = var.computeGallery.imageDefinitions[index(var.computeGallery.imageDefinitions.*.name, each.value.source.imageDefinition.name)].publisher
        offer     = var.computeGallery.imageDefinitions[index(var.computeGallery.imageDefinitions.*.name, each.value.source.imageDefinition.name)].offer
        sku       = var.computeGallery.imageDefinitions[index(var.computeGallery.imageDefinitions.*.name, each.value.source.imageDefinition.name)].sku
        version   = var.image.linux.version
      }
      optimize = {
        vmBoot = {
          state = "Enabled"
        }
      }
      errorHandling = {
        onValidationError = var.imageBuilder.errorHandling.validationMode
        onCustomizerError = var.imageBuilder.errorHandling.customizationMode
      }
      customize = concat(
        [
          {
            type        = "File"
            sourceUri   = "https://raw.githubusercontent.com/Azure/ArtistAnywhere/main/0.Foundation/functions.sh"
            destination = "/tmp/functions.sh"
          },
          {
            type        = "File"
            sourceUri   = "https://raw.githubusercontent.com/Azure/ArtistAnywhere/main/2.Image/Linux/customize.sh"
            destination = "/tmp/customize.sh"
          },
          {
            type        = "File"
            sourceUri   = "https://raw.githubusercontent.com/Azure/ArtistAnywhere/main/2.Image/Linux/customize.gpu.sh"
            destination = "/tmp/customize.gpu.sh"
          },
          {
            type        = "File"
            sourceUri   = "https://raw.githubusercontent.com/Azure/ArtistAnywhere/main/2.Image/Linux/customize.job.manager.sh"
            destination = "/tmp/customize.job.manager.sh"
          },
          {
            type        = "File"
            sourceUri   = "https://raw.githubusercontent.com/Azure/ArtistAnywhere/main/2.Image/Linux/customize.job.processor.sh"
            destination = "/tmp/customize.job.processor.sh"
          },
          {
            type        = "File"
            sourceUri   = "https://raw.githubusercontent.com/Azure/ArtistAnywhere/main/2.Image/Linux/terminate.sh"
            destination = "/tmp/terminate.sh"
          }
        ],
        [
          {
            type = "Shell"
            inline = [
              "hostname ${each.value.name}"
            ]
          },
          {
            type = "Shell"
            inline = [
              "cat /tmp/customize.sh | tr -d \r | imageBuildConfigEncoded=${base64encode(jsonencode(merge(each.value.build, {blobStorage = local.blobStorage}, {appVersion = local.appVersion}, {authCredential = local.authCredential})))} /bin/bash",
              "cat /tmp/customize.gpu.sh | tr -d \r | imageBuildConfigEncoded=${base64encode(jsonencode(merge(each.value.build, {blobStorage = local.blobStorage}, {appVersion = local.appVersion}, {authCredential = local.authCredential})))} /bin/bash",
              "cat /tmp/customize.job.manager.sh | tr -d \r | imageBuildConfigEncoded=${base64encode(jsonencode(merge(each.value.build, {blobStorage = local.blobStorage}, {appVersion = local.appVersion}, {authCredential = local.authCredential})))} /bin/bash",
              "cat /tmp/customize.job.processor.sh | tr -d \r | imageBuildConfigEncoded=${base64encode(jsonencode(merge(each.value.build, {blobStorage = local.blobStorage}, {appVersion = local.appVersion}, {authCredential = local.authCredential})))} /bin/bash"
            ]
          }
        ]
      )
      distribute = [
        {
          type           = "SharedImage"
          runOutputName  = "${each.value.name}-${each.value.build.imageVersion}"
          galleryImageId = "${azurerm_shared_image.main[each.value.source.imageDefinition.name].id}/versions/${each.value.build.imageVersion}"
          targetRegions = [
            for location in concat([azurerm_shared_image_gallery.main.location], var.imageBuilder.distribute.replicaRegions) : {
              name               = location
              replicaCount       = var.imageBuilder.distribute.replicaCount
              storageAccountType = var.imageBuilder.distribute.storageAccount.type
            }
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
  }
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
    for imageTemplate in var.imageBuilder.templates : imageTemplate.name => imageTemplate if (var.image.windows.cluster.enable && imageTemplate.enable && strcontains(lower(imageTemplate.source.imageDefinition.name), "win")) || (!var.image.windows.cluster.enable && strcontains(lower(imageTemplate.source.imageDefinition.name), "winuser"))
  }
  name      = each.value.name
  type      = "Microsoft.VirtualMachineImages/imageTemplates@2024-02-01"
  parent_id = azurerm_resource_group.image_builder.id
  location  = azurerm_resource_group.image_builder.location
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.main.id
    ]
  }
  body = {
    properties = {
      buildTimeoutInMinutes = each.value.build.timeoutMinutes
      vmProfile = {
        vmSize       = each.value.build.machineSize
        osDiskSizeGB = each.value.build.osDiskSizeGB
        userAssignedIdentities = [
          data.azurerm_user_assigned_identity.main.id
        ]
        vnetConfig = {
          subnetId = data.azurerm_subnet.main.id
        }
      }
      source = {
        type      = "PlatformImage"
        publisher = var.computeGallery.imageDefinitions[index(var.computeGallery.imageDefinitions.*.name, each.value.source.imageDefinition.name)].publisher
        offer     = var.computeGallery.imageDefinitions[index(var.computeGallery.imageDefinitions.*.name, each.value.source.imageDefinition.name)].offer
        sku       = var.computeGallery.imageDefinitions[index(var.computeGallery.imageDefinitions.*.name, each.value.source.imageDefinition.name)].sku
        version   = var.image.windows.version
      }
      optimize = {
        vmBoot = {
          state = "Enabled"
        }
      }
      errorHandling = {
        onValidationError = var.imageBuilder.errorHandling.validationMode
        onCustomizerError = var.imageBuilder.errorHandling.customizationMode
      }
      customize = concat(
        [
          {
            type        = "File"
            sourceUri   = "https://raw.githubusercontent.com/Azure/ArtistAnywhere/main/0.Foundation/functions.ps1"
            destination = "C:\\AzureData\\functions.ps1"
          },
          {
            type        = "File"
            sourceUri   = "https://raw.githubusercontent.com/Azure/ArtistAnywhere/main/2.Image/Windows/customize.ps1"
            destination = "C:\\AzureData\\customize.ps1"
          },
          {
            type        = "File"
            sourceUri   = "https://raw.githubusercontent.com/Azure/ArtistAnywhere/main/2.Image/Windows/customize.gpu.ps1"
            destination = "C:\\AzureData\\customize.gpu.ps1"
          },
          {
            type        = "File"
            sourceUri   = "https://raw.githubusercontent.com/Azure/ArtistAnywhere/main/2.Image/Windows/customize.job.manager.ps1"
            destination = "C:\\AzureData\\customize.job.manager.ps1"
          },
          {
            type        = "File"
            sourceUri   = "https://raw.githubusercontent.com/Azure/ArtistAnywhere/main/2.Image/Windows/customize.job.processor.ps1"
            destination = "C:\\AzureData\\customize.job.processor.ps1"
          },
          {
            type        = "File"
            sourceUri   = "https://raw.githubusercontent.com/Azure/ArtistAnywhere/main/2.Image/Windows/terminate.ps1"
            destination = "C:\\AzureData\\terminate.ps1"
          }
        ],
        [
          {
            type = "PowerShell"
            inline = [
              "Rename-Computer -NewName ${each.value.name} -Force"
            ]
          },
          {
            type = "WindowsRestart"
          },
          {
            type = "PowerShell"
            inline = [
              "C:\\AzureData\\customize.ps1 -imageBuildConfigEncoded ${base64encode(jsonencode(merge(each.value.build, {blobStorage = local.blobStorage}, {appVersion = local.appVersion}, {authCredential = local.authCredential})))}",
              "C:\\AzureData\\customize.gpu.ps1 -imageBuildConfigEncoded ${base64encode(jsonencode(merge(each.value.build, {blobStorage = local.blobStorage}, {appVersion = local.appVersion}, {authCredential = local.authCredential})))}",
              "C:\\AzureData\\customize.job.manager.ps1 -imageBuildConfigEncoded ${base64encode(jsonencode(merge(each.value.build, {blobStorage = local.blobStorage}, {appVersion = local.appVersion}, {authCredential = local.authCredential})))}",
              "C:\\AzureData\\customize.job.processor.ps1 -imageBuildConfigEncoded ${base64encode(jsonencode(merge(each.value.build, {blobStorage = local.blobStorage}, {appVersion = local.appVersion}, {authCredential = local.authCredential})))}"
            ]
            runElevated = true
            runAsSystem = true
          }
        ]
      )
      distribute = [
        {
          type           = "SharedImage"
          runOutputName  = "${each.value.name}-${each.value.build.imageVersion}"
          galleryImageId = "${azurerm_shared_image.main[each.value.source.imageDefinition.name].id}/versions/${each.value.build.imageVersion}"
          targetRegions = [
            for location in concat([azurerm_shared_image_gallery.main.location], var.imageBuilder.distribute.replicaRegions) : {
              name               = location
              replicaCount       = var.imageBuilder.distribute.replicaCount
              storageAccountType = var.imageBuilder.distribute.storageAccount.type
            }
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
  }
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
