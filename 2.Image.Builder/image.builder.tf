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
    storage = object({
      binHostUrl = string
      authClient = object({
        id     = string
        secret = string
      })
    })
    script = object({
      jobScheduler = object({
        deadline = bool
        slurm    = bool
      })
      jobProcessor = object({
        render = bool
        eda    = bool
      })
    })
  })
  validation {
    condition     = var.imageCustomize.storage.authClient.id != "" && var.imageCustomize.storage.authClient.secret != ""
    error_message = "Missing required image customize Azure Storage auth client configuration."
  }
}

locals {
  authClient = {
    tenantId       = data.azurerm_client_config.current.tenant_id
    clientId       = var.imageCustomize.storage.authClient.id
    clientSecret   = var.imageCustomize.storage.authClient.secret
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
        # planInfo = {
        #   planPublisher = lower(var.computeGallery.imageDefinitions[index(var.computeGallery.imageDefinitions.*.name, each.value.source.imageDefinition.name)].publisher)
        #   planProduct   = lower(var.computeGallery.imageDefinitions[index(var.computeGallery.imageDefinitions.*.name, each.value.source.imageDefinition.name)].offer)
        #   planName      = lower(var.computeGallery.imageDefinitions[index(var.computeGallery.imageDefinitions.*.name, each.value.source.imageDefinition.name)].sku)
        # }
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
            sourceUri   = "https://raw.githubusercontent.com/Azure/ArtistAnywhere/main/2.Image.Builder/Linux/customize.job.processor.render.sh"
            destination = "/tmp/customize.job.processor.render.sh"
          },
          {
            type        = "File"
            sourceUri   = "https://raw.githubusercontent.com/Azure/ArtistAnywhere/main/2.Image.Builder/Linux/customize.job.processor.eda.sh"
            destination = "/tmp/customize.job.processor.eda.sh"
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
              "cat /tmp/customize.core.sh | tr -d \r | buildConfigEncoded=${base64encode(jsonencode(merge(each.value.build, {version = module.global.version}, {authClient = local.authClient}, {authCredential = local.authCredential}, {binHostUrl = var.imageCustomize.storage.binHostUrl})))} /bin/bash",
              "cat /tmp/customize.core.gpu.sh | tr -d \r | buildConfigEncoded=${base64encode(jsonencode(merge(each.value.build, {version = module.global.version}, {authClient = local.authClient}, {authCredential = local.authCredential}, {binHostUrl = var.imageCustomize.storage.binHostUrl})))} /bin/bash",
              "if [ ${var.imageCustomize.script.jobScheduler.deadline} == true ]; then",
              "  cat /tmp/customize.job.scheduler.deadline.sh | tr -d \r | buildConfigEncoded=${base64encode(jsonencode(merge(each.value.build, {version = module.global.version}, {authClient = local.authClient}, {authCredential = local.authCredential}, {binHostUrl = var.imageCustomize.storage.binHostUrl})))} /bin/bash",
              "fi",
              "if [ ${var.imageCustomize.script.jobScheduler.slurm} == true ]; then",
              "  cat /tmp/customize.job.scheduler.slurm.sh | tr -d \r | buildConfigEncoded=${base64encode(jsonencode(merge(each.value.build, {version = module.global.version}, {authClient = local.authClient}, {authCredential = local.authCredential}, {binHostUrl = var.imageCustomize.storage.binHostUrl})))} /bin/bash",
              "fi",
              "if [ ${var.imageCustomize.script.jobProcessor.render} == true ]; then",
              "  cat /tmp/customize.job.processor.render.sh | tr -d \r | buildConfigEncoded=${base64encode(jsonencode(merge(each.value.build, {version = module.global.version}, {authClient = local.authClient}, {authCredential = local.authCredential}, {binHostUrl = var.imageCustomize.storage.binHostUrl})))} /bin/bash",
              "fi",
              "if [ ${var.imageCustomize.script.jobProcessor.eda} == true ]; then",
              "  cat /tmp/customize.job.processor.eda.sh | tr -d \r | buildConfigEncoded=${base64encode(jsonencode(merge(each.value.build, {version = module.global.version}, {authClient = local.authClient}, {authCredential = local.authCredential}, {binHostUrl = var.imageCustomize.storage.binHostUrl})))} /bin/bash",
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
            sourceUri   = "https://raw.githubusercontent.com/Azure/ArtistAnywhere/main/2.Image.Builder/Windows/customize.job.scheduler.deadline.ps1"
            destination = "C:\\AzureData\\customize.job.scheduler.deadline.ps1"
          },
          {
            type        = "File"
            sourceUri   = "https://raw.githubusercontent.com/Azure/ArtistAnywhere/main/2.Image.Builder/Windows/customize.job.processor.render.ps1"
            destination = "C:\\AzureData\\customize.job.processor.render.ps1"
          },
          {
            type        = "File"
            sourceUri   = "https://raw.githubusercontent.com/Azure/ArtistAnywhere/main/2.Image.Builder/Windows/customize.job.processor.eda.ps1"
            destination = "C:\\AzureData\\customize.job.processor.eda.ps1"
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
              "}",
              "if ('${each.value.build.machineType}' -eq 'JobScheduler') {",
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
              "  C:\\AzureData\\customize.core.ps1 -buildConfigEncoded ${base64encode(jsonencode(merge(each.value.build, {version = module.global.version}, {authClient = local.authClient}, {authCredential = local.authCredential}, {binHostUrl = var.imageCustomize.storage.binHostUrl})))}",
              "  C:\\AzureData\\customize.core.gpu.ps1 -buildConfigEncoded ${base64encode(jsonencode(merge(each.value.build, {version = module.global.version}, {authClient = local.authClient}, {authCredential = local.authCredential}, {binHostUrl = var.imageCustomize.storage.binHostUrl})))}",
              "  if ('${var.imageCustomize.script.jobScheduler.deadline}' -eq $true) {",
              "    C:\\AzureData\\customize.job.scheduler.deadline.ps1 -buildConfigEncoded ${base64encode(jsonencode(merge(each.value.build, {version = module.global.version}, {authClient = local.authClient}, {authCredential = local.authCredential}, {binHostUrl = var.imageCustomize.storage.binHostUrl})))}",
              "  }",
              "  if ('${var.imageCustomize.script.jobProcessor.render}' -eq $true) {",
              "    C:\\AzureData\\customize.job.processor.render.ps1 -buildConfigEncoded ${base64encode(jsonencode(merge(each.value.build, {version = module.global.version}, {authClient = local.authClient}, {authCredential = local.authCredential}, {binHostUrl = var.imageCustomize.storage.binHostUrl})))}",
              "  }",
              "  if ('${var.imageCustomize.script.jobProcessor.eda}' -eq $true) {",
              "    C:\\AzureData\\customize.job.processor.eda.ps1 -buildConfigEncoded ${base64encode(jsonencode(merge(each.value.build, {version = module.global.version}, {authClient = local.authClient}, {authCredential = local.authCredential}, {binHostUrl = var.imageCustomize.storage.binHostUrl})))}",
              "  }",
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
