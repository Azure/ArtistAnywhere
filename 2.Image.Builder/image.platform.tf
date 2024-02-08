#############################################################################################
# Image Builder (https://learn.microsoft.com/azure/virtual-machines/image-builder-overview) #
#############################################################################################

resource azapi_resource image_platform_linux {
  for_each = {
    for imageTemplate in var.imageBuilder.templates : imageTemplate.name => imageTemplate if var.computeGallery.enable && var.computeGallery.platform.linux.enable && imageTemplate.enable && imageTemplate.source.imageDefinition.name == "Linux" && imageTemplate.build.imageVersion == "0.0.0"
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
      customize = [
        {
          type   = "Shell"
          inline = each.value.build.customization
        }
      ]
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
  depends_on = [
    azurerm_role_assignment.identity,
    azurerm_role_assignment.network,
    azurerm_role_assignment.image
  ]
}

resource terraform_data image_platform_linux_build {
  for_each = azapi_resource.image_platform_linux
  provisioner local-exec {
    command = "az image builder run --resource-group ${azurerm_resource_group.image.name} --name ${each.value.name}"
  }
}
