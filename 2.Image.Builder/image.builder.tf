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
        jobSchedulers  = list(string)
        jobProcessors  = list(string)
      })
      distribute = object({
        storageAccountType = string
        replicaCount       = number
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
    blobStorage = object({
      binHostUrl = string
      authClient = object({
        id     = string
        secret = string
      })
    })
  })
  validation {
    condition     = var.imageCustomize.blobStorage.authClient.id != "" && var.imageCustomize.blobStorage.authClient.secret != ""
    error_message = "Missing required image customize Azure Blob Storage auth client configuration."
  }
}

locals {
  authClient = {
    tenantId       = data.azurerm_client_config.current.tenant_id
    clientId       = var.imageCustomize.blobStorage.authClient.id
    clientSecret   = var.imageCustomize.blobStorage.authClient.secret
    storageVersion = "2025-01-05"
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
  principal_id         = data.azurerm_user_assigned_identity.studio.principal_id
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
    for imageTemplate in var.imageBuilder.templates : imageTemplate.name => imageTemplate if var.computeGallery.platform.linux.enable && imageTemplate.enable && lower(imageTemplate.source.imageDefinition.name) == "linux"
  }
  name      = each.value.name
  type      = "Microsoft.VirtualMachineImages/imageTemplates@2024-02-01"
  parent_id = azurerm_resource_group.image_builder.id
  location  = azurerm_resource_group.image_builder.location
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  body = {
    properties = {
      buildTimeoutInMinutes = each.value.build.timeoutMinutes
      vmProfile = {
        vmSize       = each.value.build.machineSize
        osDiskSizeGB = each.value.build.osDiskSizeGB
        userAssignedIdentities = [
          data.azurerm_user_assigned_identity.studio.id
        ]
        vnetConfig = {
          subnetId = data.azurerm_subnet.compute.id
        }
      }
      source = {
        type      = "PlatformImage"
        publisher = var.computeGallery.imageDefinitions[index(var.computeGallery.imageDefinitions.*.name, each.value.source.imageDefinition.name)].publisher
        offer     = var.computeGallery.imageDefinitions[index(var.computeGallery.imageDefinitions.*.name, each.value.source.imageDefinition.name)].offer
        sku       = var.computeGallery.imageDefinitions[index(var.computeGallery.imageDefinitions.*.name, each.value.source.imageDefinition.name)].sku
        version   = var.computeGallery.platform.linux.version
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
            sourceUri   = "https://raw.githubusercontent.com/Azure/ArtistAnywhere/main/2.Image.Builder/Linux/customize.core.gpu.sh"
            destination = "/tmp/customize.core.gpu.sh"
          },
          {
            type        = "File"
            sourceUri   = "https://raw.githubusercontent.com/Azure/ArtistAnywhere/main/2.Image.Builder/Linux/customize.job.scheduler.sh"
            destination = "/tmp/customize.job.scheduler.sh"
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
              "hostname ${each.value.name}"
            ]
          },
          {
            type = "Shell"
            inline = [
              "cat /tmp/customize.core.sh | tr -d \r | buildConfigEncoded=${base64encode(jsonencode(merge(each.value.build, {version = module.global.version}, {authClient = local.authClient}, {authCredential = local.authCredential}, {binHostUrl = var.imageCustomize.blobStorage.binHostUrl})))} /bin/bash",
              "cat /tmp/customize.core.gpu.sh | tr -d \r | buildConfigEncoded=${base64encode(jsonencode(merge(each.value.build, {version = module.global.version}, {authClient = local.authClient}, {authCredential = local.authCredential}, {binHostUrl = var.imageCustomize.blobStorage.binHostUrl})))} /bin/bash",
              "cat /tmp/customize.job.scheduler.sh | tr -d \r | buildConfigEncoded=${base64encode(jsonencode(merge(each.value.build, {version = module.global.version}, {authClient = local.authClient}, {authCredential = local.authCredential}, {binHostUrl = var.imageCustomize.blobStorage.binHostUrl})))} /bin/bash",
              "cat /tmp/customize.job.processor.sh | tr -d \r | buildConfigEncoded=${base64encode(jsonencode(merge(each.value.build, {version = module.global.version}, {authClient = local.authClient}, {authCredential = local.authCredential}, {binHostUrl = var.imageCustomize.blobStorage.binHostUrl})))} /bin/bash",
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
    for imageTemplate in var.imageBuilder.templates : imageTemplate.name => imageTemplate if var.computeGallery.platform.windows.enable && imageTemplate.enable && startswith(imageTemplate.source.imageDefinition.name, "Win")
  }
  name      = each.value.name
  type      = "Microsoft.VirtualMachineImages/imageTemplates@2024-02-01"
  parent_id = azurerm_resource_group.image_builder.id
  location  = azurerm_resource_group.image_builder.location
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  body = {
    properties = {
      buildTimeoutInMinutes = each.value.build.timeoutMinutes
      vmProfile = {
        vmSize       = each.value.build.machineSize
        osDiskSizeGB = each.value.build.osDiskSizeGB
        userAssignedIdentities = [
          data.azurerm_user_assigned_identity.studio.id
        ]
        vnetConfig = {
          subnetId = data.azurerm_subnet.compute.id
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
            sourceUri   = "https://raw.githubusercontent.com/Azure/ArtistAnywhere/main/2.Image.Builder/Windows/customize.core.gpu.ps1"
            destination = "C:\\AzureData\\customize.core.gpu.ps1"
          },
          {
            type        = "File"
            sourceUri   = "https://raw.githubusercontent.com/Azure/ArtistAnywhere/main/2.Image.Builder/Windows/customize.job.scheduler.ps1"
            destination = "C:\\AzureData\\customize.job.scheduler.ps1"
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
              "if ('${each.value.build.machineType}' -eq 'DomainController') {",
                "Write-Host 'Customize (Start): AD Domain Services'",
                "Install-WindowsFeature -Name 'AD-Domain-Services' -IncludeManagementTools",
                "Write-Host 'Customize (End): AD Domain Services'",
              "} elseif ('${each.value.build.machineType}' -eq 'Scheduler') {",
                "Write-Host 'Customize (Start): NFS Server'",
                "Install-WindowsFeature -Name 'FS-NFS-Service'",
                "Write-Host 'Customize (End): NFS Server'",
              "}",
              "Rename-Computer -NewName ${each.value.name} -Force"
            ]
          },
          {
            type = "WindowsRestart"
          },
          {
            type = "PowerShell"
            inline = [
              "if ('${each.value.build.machineType}' -ne 'DomainController') {",
              "  C:\\AzureData\\customize.core.ps1 -buildConfigEncoded ${base64encode(jsonencode(merge(each.value.build, {version = module.global.version}, {authClient = local.authClient}, {authCredential = local.authCredential}, {binHostUrl = var.imageCustomize.blobStorage.binHostUrl})))}",
              "  C:\\AzureData\\customize.core.gpu.ps1 -buildConfigEncoded ${base64encode(jsonencode(merge(each.value.build, {version = module.global.version}, {authClient = local.authClient}, {authCredential = local.authCredential}, {binHostUrl = var.imageCustomize.blobStorage.binHostUrl})))}",
              "  C:\\AzureData\\customize.job.scheduler.ps1 -buildConfigEncoded ${base64encode(jsonencode(merge(each.value.build, {version = module.global.version}, {authClient = local.authClient}, {authCredential = local.authCredential}, {binHostUrl = var.imageCustomize.blobStorage.binHostUrl})))}",
              "  C:\\AzureData\\customize.job.processor.ps1 -buildConfigEncoded ${base64encode(jsonencode(merge(each.value.build, {version = module.global.version}, {authClient = local.authClient}, {authCredential = local.authCredential}, {binHostUrl = var.imageCustomize.blobStorage.binHostUrl})))}",
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
