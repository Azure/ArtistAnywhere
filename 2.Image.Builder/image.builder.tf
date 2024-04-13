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
          name    = string
          version = string
        })
        # imageVersion = object({
        #   id = string
        # })
      })
      build = object({
        machineType    = string
        machineSize    = string
        gpuProvider    = string
        imageVersion   = string
        osDiskSizeGB   = number
        timeoutMinutes = number
        renderEngines  = list(string)
        customization  = list(string)
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

variable versionPath {
  type = object({
    nvidiaCUDA        = string
    nvidiaCUDAToolkit = string
    nvidiaOptiX       = string
    renderPBRT        = string
    renderBlender     = string
    renderMaya        = string
    renderHoudini     = string
    renderUnrealVS    = string
    renderUnreal      = string
    renderUnrealPixel = string
    jobScheduler      = string
    pcoipAgent        = string
  })
}

variable dataPlatform {
  type = object({
    adminLogin = object({
      userName     = string
      userPassword = string
    })
    jobDatabase = object({
      host = string
      port = number
      serviceLogin = object({
        userName     = string
        userPassword = string
      })
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
  dataPlatform = {
    adminLogin = {
      userName     = var.dataPlatform.adminLogin.userName != "" || !module.global.keyVault.enable ? var.dataPlatform.adminLogin.userName : data.azurerm_key_vault_secret.admin_username[0].value
      userPassword = var.dataPlatform.adminLogin.userPassword != "" || !module.global.keyVault.enable ? var.dataPlatform.adminLogin.userPassword : data.azurerm_key_vault_secret.admin_password[0].value
    }
    jobDatabase = {
      host = var.dataPlatform.jobDatabase.host
      port = var.dataPlatform.jobDatabase.port
      serviceLogin = {
        userName     = var.dataPlatform.jobDatabase.serviceLogin.userName != "" || !module.global.keyVault.enable ? var.dataPlatform.jobDatabase.serviceLogin.userName : data.azurerm_key_vault_secret.database_username[0].value
        userPassword = var.dataPlatform.jobDatabase.serviceLogin.userPassword != "" || !module.global.keyVault.enable ? var.dataPlatform.jobDatabase.serviceLogin.userPassword : data.azurerm_key_vault_secret.database_password[0].value
      }
    }
  }
}

resource azurerm_role_assignment identity {
  role_definition_name = "Managed Identity Operator" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#managed-identity-operator
  principal_id         = data.azurerm_user_assigned_identity.studio.principal_id
  scope                = data.azurerm_user_assigned_identity.studio.id
}

resource azurerm_role_assignment network {
  role_definition_name = "Virtual Machine Contributor" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#virtual-machine-contributor
  principal_id         = data.azurerm_user_assigned_identity.studio.principal_id
  scope                = data.azurerm_resource_group.network.id
}

resource azurerm_role_assignment image {
  role_definition_name = "Contributor" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#contributor
  principal_id         = data.azurerm_user_assigned_identity.studio.principal_id
  scope                = azurerm_resource_group.image.id
}

resource azapi_resource linux {
  for_each = {
    for imageTemplate in var.imageBuilder.templates : imageTemplate.name => imageTemplate if var.computeGallery.platform.linux.enable && imageTemplate.enable && lower(imageTemplate.source.imageDefinition.name) == "linux"
  }
  name      = each.value.name
  type      = "Microsoft.VirtualMachineImages/imageTemplates@2023-07-01"
  parent_id = azurerm_resource_group.image.id
  location  = azurerm_resource_group.image.location
  body = jsonencode({
    identity = {
      type = "UserAssigned"
      userAssignedIdentities = {
        "${data.azurerm_user_assigned_identity.studio.id}" : {}
      }
    }
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
        version   = each.value.source.imageDefinition.version
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
            inline      = null
          },
          {
            type        = "File"
            sourceUri   = "https://raw.githubusercontent.com/Azure/ArtistAnywhere/main/2.Image.Builder/customize.sh"
            destination = "/tmp/customize.sh"
            inline      = null
          },
          {
            type        = "File"
            sourceUri   = "https://raw.githubusercontent.com/Azure/ArtistAnywhere/main/2.Image.Builder/terminate.sh"
            destination = "/tmp/terminate.sh"
            inline      = null
          }
        ], length(each.value.build.customization) > 0 ?
        [
          {
            type   = "Shell"
            inline = each.value.build.customization
          }
        ] : [
          {
            type = "Shell"
            inline = [
              "hostname ${each.value.name}"
            ]
          },
          {
            type = "Shell"
            inline = [
              "cat /tmp/customize.sh | tr -d \r | buildConfigEncoded=${base64encode(jsonencode(merge(each.value.build, {versionPath = var.versionPath}, {dataPlatform = local.dataPlatform}, {binStorage = var.binStorage})))} /bin/bash"
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
    azurerm_marketplace_agreement.linux,
    azurerm_role_assignment.identity,
    azurerm_role_assignment.network,
    azurerm_role_assignment.image
  ]
}

resource azapi_resource windows {
  for_each = {
    for imageTemplate in var.imageBuilder.templates : imageTemplate.name => imageTemplate if var.computeGallery.platform.windows.enable && imageTemplate.enable && startswith(imageTemplate.source.imageDefinition.name, "Win")
  }
  name      = each.value.name
  type      = "Microsoft.VirtualMachineImages/imageTemplates@2023-07-01"
  parent_id = azurerm_resource_group.image.id
  location  = azurerm_resource_group.image.location
  body = jsonencode({
    identity = {
      type = "UserAssigned"
      userAssignedIdentities = {
        "${data.azurerm_user_assigned_identity.studio.id}" : {}
      }
    }
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
        version   = each.value.source.imageDefinition.version
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
            sourceUri   = "https://raw.githubusercontent.com/Azure/ArtistAnywhere/main/0.Global.Foundation/functions.psm1"
            destination = "C:\\AzureData\\functions.psm1"
            inline      = null
            runElevated = false
            runAsSystem = false
          },
          {
            type        = "File"
            sourceUri   = "https://raw.githubusercontent.com/Azure/ArtistAnywhere/main/2.Image.Builder/customize.ps1"
            destination = "C:\\AzureData\\customize.ps1"
            inline      = null
            runElevated = false
            runAsSystem = false
          },
          {
            type        = "File"
            sourceUri   = "https://raw.githubusercontent.com/Azure/ArtistAnywhere/main/2.Image.Builder/terminate.ps1"
            destination = "C:\\AzureData\\terminate.ps1"
            inline      = null
            runElevated = false
            runAsSystem = false
          }
        ], length(each.value.build.customization) > 0 ?
        [
          {
            type        = "PowerShell"
            inline      = each.value.build.customization
            runElevated = false
            runAsSystem = false
          }
        ] : [
          {
            type = "PowerShell"
            inline = [
              "Rename-Computer -NewName ${each.value.name}",
              "dism /Online /NoRestart /Enable-Feature /FeatureName:VirtualMachinePlatform /All",
              "dism /Online /NoRestart /Enable-Feature /FeatureName:Microsoft-Windows-Subsystem-Linux /All",
              "exit 0"
            ]
            runElevated = false
            runAsSystem = false
          },
          {
            type        = "WindowsRestart"
            inline      = null
            runElevated = false
            runAsSystem = false
          },
          {
            type = "PowerShell"
            inline = [
              "C:\\AzureData\\customize.ps1 -buildConfigEncoded ${base64encode(jsonencode(merge(each.value.build, {versionPath = var.versionPath}, {dataPlatform = local.dataPlatform}, {binStorage = var.binStorage})))}"
            ]
            runElevated = true
            runAsSystem = true
          },
          {
            type        = "WindowsRestart"
            inline      = null
            runElevated = false
            runAsSystem = false
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
    azurerm_role_assignment.identity,
    azurerm_role_assignment.network,
    azurerm_role_assignment.image
  ]
}
