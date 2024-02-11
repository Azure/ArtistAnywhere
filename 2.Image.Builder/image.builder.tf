#############################################################################################
# Image Builder (https://learn.microsoft.com/azure/virtual-machines/image-builder-overview) #
#############################################################################################

variable imageBuilder {
  type = object({
    templates = list(object({
      name   = string
      enable = bool
      source = object({
        imageDefinition = object({
          name    = string
          version = string
        })
        imageVersion = object({
          id = string
        })
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
      errorHandling = object({
        validationMode    = string
        customizationMode = string
      })
    }))
  })
}

locals {
  regionNames = var.existingNetwork.enable ? [module.global.regionName] : [
    for virtualNetwork in data.terraform_remote_state.network.outputs.virtualNetworks : virtualNetwork.regionName
  ]
  targetRegions = [
    for regionName in local.regionNames : {
      name               = regionName
      replicaCount       = 1
      storageAccountType = "Standard_LRS"
    }
  ]
  dataPlatform = {
    admin = {
      username = data.azurerm_key_vault_secret.admin_username.value
      password = data.azurerm_key_vault_secret.admin_password.value
    }
    database = {
      username = data.azurerm_key_vault_secret.database_username.value
      password = data.azurerm_key_vault_secret.database_password.value
      cosmosDB = var.cosmosDB.enable
      host     = var.cosmosDB.enable ? "${var.cosmosDB.name}.mongocluster.cosmos.azure.com" : ""
      port     = var.cosmosDB.enable ? 10255 : 27017
    }
  }
}

resource azurerm_role_assignment identity {
  count                = var.computeGallery.enable ? 1 : 0
  role_definition_name = "Managed Identity Operator" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#managed-identity-operator
  principal_id         = data.azurerm_user_assigned_identity.studio.principal_id
  scope                = data.azurerm_user_assigned_identity.studio.id
}

resource azurerm_role_assignment network {
  count                = var.computeGallery.enable ? 1 : 0
  role_definition_name = "Virtual Machine Contributor" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#virtual-machine-contributor
  principal_id         = data.azurerm_user_assigned_identity.studio.principal_id
  scope                = data.azurerm_resource_group.network.id
}

resource azurerm_role_assignment image {
  count                = var.computeGallery.enable ? 1 : 0
  role_definition_name = "Contributor" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#contributor
  principal_id         = data.azurerm_user_assigned_identity.studio.principal_id
  scope                = azurerm_resource_group.image.id
}

resource azapi_resource image_builder_linux {
  for_each = {
    for imageTemplate in var.imageBuilder.templates : imageTemplate.name => imageTemplate if var.computeGallery.enable && var.computeGallery.platform.linux.enable && imageTemplate.enable && imageTemplate.source.imageDefinition.name == "Linux" && imageTemplate.build.imageVersion != "0.0.0"
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
        type           = "SharedImageVersion"
        imageVersionId = each.value.source.imageVersion.id
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
              "cat /tmp/customize.sh | tr -d \r | buildConfigEncoded=${base64encode(jsonencode(merge(each.value.build, {binStorage = var.binStorage}, {dataPlatform = local.dataPlatform})))} /bin/bash"
            ]
          }
        ]
      )
      distribute = [
        {
          type           = "SharedImage"
          runOutputName  = "${each.value.name}-${each.value.build.imageVersion}"
          galleryImageId = "${azurerm_shared_image.linux[each.value.source.imageDefinition.name].id}/versions/${each.value.build.imageVersion}"
          versioning = {
            scheme = "Latest"
            major  = tonumber(split(".", each.value.build.imageVersion)[0])
          }
          targetRegions = local.targetRegions
          artifactTags = {
            imageTemplateName = each.value.name
          }
        }
      ]
    }
  })
  schema_validation_enabled = false
  depends_on = [
    azurerm_role_assignment.identity,
    azurerm_role_assignment.network,
    azurerm_role_assignment.image,
    terraform_data.image_platform_linux_build
  ]
}

resource azapi_resource image_builder_windows {
  for_each = {
    for imageTemplate in var.imageBuilder.templates : imageTemplate.name => imageTemplate if var.computeGallery.enable && var.computeGallery.platform.windows.enable && imageTemplate.enable && startswith(imageTemplate.source.imageDefinition.name, "Win")
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
            sourceUri   = "https://raw.githubusercontent.com/Azure/ArtistAnywhere/main/0.Global.Foundation/functions.ps1"
            destination = "C:\\AzureData\\functions.ps1"
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
              "C:\\AzureData\\customize.ps1 -buildConfigEncoded ${base64encode(jsonencode(merge(each.value.build, {binStorage = var.binStorage})))}"
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
          galleryImageId = "${azurerm_shared_image.windows[each.value.source.imageDefinition.name].id}/versions/${each.value.build.imageVersion}"
          versioning = {
            scheme = "Latest"
            major  = tonumber(split(".", each.value.build.imageVersion)[0])
          }
          targetRegions = local.targetRegions
          artifactTags = {
            imageTemplateName = each.value.name
          }
        }
      ]
    }
  })
  schema_validation_enabled = false
  depends_on = [
    azurerm_role_assignment.identity,
    azurerm_role_assignment.network,
    azurerm_role_assignment.image
  ]
}
