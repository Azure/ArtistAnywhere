##################################################################################
# Compute Fleet (https://learn.microsoft.com/azure/azure-compute-fleet/overview) #
##################################################################################

variable computeFleets {
  type = list(object({
    enable = bool
    name   = string
    machine = object({
      namePrefix = string
      sizes = list(object({
        name = string
      }))
      image = object({
        resourceGroupName = string
        galleryName       = string
        definitionName    = string
        versionId         = string
        plan = object({
          publisher = string
          product   = string
          name      = string
        })
      })
      osDisk = object({
        type        = string
        storageType = string
        cachingType = string
        sizeGB      = number
        ephemeral = object({
          enable    = bool
          placement = string
        })
      })
      priority = object({
        standard = object({
          allocationStrategy = string
          capacityTarget     = number
          capacityMinimum    = number
        })
        spot = object({
          allocationStrategy = string
          evictionPolicy     = string
          capacityTarget     = number
          capacityMinimum    = number
          capacityMaintain = object({
            enable = bool
          })
        })
      })
      extension = object({
        custom = object({
          enable   = bool
          name     = string
          fileName = string
          parameters = object({
            terminateNotification = object({
              enable       = bool
              delayTimeout = string
            })
          })
        })
        health = object({
          enable      = bool
          name        = string
          protocol    = string
          port        = number
          requestPath = string
        })
        monitor = object({
          enable = bool
          name   = string
        })
      })
      adminLogin = object({
        userName     = string
        userPassword = string
        sshKeyPublic = string
      })
    })
    network = object({
      subnetName = string
      acceleration = object({
        enable = bool
      })
      locationExtended = object({
        enable = bool
      })
    })
  }))
}

locals {
  computeFleets = [
    for computeFleet in var.computeFleets : merge(computeFleet, {
      resourceLocation = {
        regionName       = computeFleet.network.locationExtended.enable ? module.global.resourceLocation.extendedZone.regionName : module.global.resourceLocation.regionName
        extendedZoneName = computeFleet.network.locationExtended.enable ? module.global.resourceLocation.extendedZone.name : null
      }
      machine = merge(computeFleet.machine, {
        image = merge(computeFleet.machine.image, {
          plan = {
            publisher = try(data.terraform_remote_state.image.outputs.linuxPlan.publisher, computeFleet.machine.image.plan.publisher)
            product   = try(data.terraform_remote_state.image.outputs.linuxPlan.offer, computeFleet.machine.image.plan.product)
            name      = try(data.terraform_remote_state.image.outputs.linuxPlan.sku, computeFleet.machine.image.plan.name)
          }
        })
        adminLogin = merge(computeFleet.machine.adminLogin, {
          userName     = computeFleet.machine.adminLogin.userName != "" ? computeFleet.machine.adminLogin.userName : data.azurerm_key_vault_secret.admin_username.value
          userPassword = computeFleet.machine.adminLogin.userPassword != "" ? computeFleet.machine.adminLogin.userPassword : data.azurerm_key_vault_secret.admin_password.value
          sshKeyPublic = computeFleet.machine.adminLogin.sshKeyPublic != "" ? computeFleet.machine.adminLogin.sshKeyPublic : data.azurerm_key_vault_secret.ssh_key_public.value
        })
      })
      network = merge(computeFleet.network, {
        subnetId = "${computeFleet.network.locationExtended.enable ? data.azurerm_virtual_network.studio_extended.id : data.azurerm_virtual_network.studio_region.id}/subnets/${var.existingNetwork.enable ? var.existingNetwork.subnetName : computeFleet.network.subnetName}"
      })
      activeDirectory = merge(var.activeDirectory, {
        adminUsername = var.activeDirectory.adminUsername != "" ? var.activeDirectory.adminUsername : data.azurerm_key_vault_secret.admin_username.value
        adminPassword = var.activeDirectory.adminPassword != "" ? var.activeDirectory.adminPassword : data.azurerm_key_vault_secret.admin_password.value
      })
    }) if computeFleet.enable
  ]
}

resource azapi_resource fleet {
  for_each = {
    for computeFleet in local.computeFleets : computeFleet.name => computeFleet
  }
  name      = each.value.name
  type      = "Microsoft.AzureFleet/fleets@2024-11-01"
  parent_id = azurerm_resource_group.farm.id
  location  = azurerm_resource_group.farm.location
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  body = {
    properties = {
      computeProfile = {
        baseVirtualMachineProfile = {
          storageProfile = {
            imageReference = {
              id = "/subscriptions/${module.global.subscriptionId}/resourceGroups/${each.value.machine.image.resourceGroupName}/providers/Microsoft.Compute/galleries/${each.value.machine.image.galleryName}/images/${each.value.machine.image.definitionName}/versions/${each.value.machine.image.versionId}"
            }
            osDisk = {
              managedDisk = {
                storageAccountType = each.value.machine.osDisk.storageType
              }
              caching    = each.value.machine.osDisk.cachingType
              diskSizeGB = each.value.machine.osDisk.sizeGB > 0 ? each.value.machine.osDisk.sizeGB : null
              # dynamic diff_disk_settings {
              #   for_each = each.value.machine.osDisk.ephemeral.enable ? [1] : []
              #   content {
              #     option    = "Local"
              #     placement = each.value.machine.osDisk.ephemeral.placement
              #   }
              # }
              createOption = "FromImage"
            }
          }
          osProfile = {
            computerNamePrefix = each.value.machine.namePrefix != "" ? each.value.machine.namePrefix : each.value.name
            adminUsername      = each.value.machine.adminLogin.userName
            adminPassword      = each.value.machine.adminLogin.userPassword
          }
          networkProfile = {
            networkApiVersion = "2024-05-01"
            networkInterfaceConfigurations = [
              {
                name = "nic"
                properties = {
                  ipConfigurations = [
                    {
                      name = "ipconfig"
                      properties = {
                        subnet = {
                          id = each.value.network.subnetId
                        }
                      }
                    }
                  ]
                  enableAcceleratedNetworking = each.value.network.acceleration.enable
                }
              }
            ]
          }
          extensionProfile = {
            extensions = [
              { # Custom
                name = each.value.machine.extension.custom.name
                properties = {
                  type                    = lower(each.value.machine.osDisk.type) == "windows" ? "CustomScriptExtension" :"CustomScript"
                  publisher               = lower(each.value.machine.osDisk.type) == "windows" ? "Microsoft.Compute" : "Microsoft.Azure.Extensions"
                  typeHandlerVersion      = lower(each.value.machine.osDisk.type) == "windows" ? "1.10" : "2.1"
                  autoUpgradeMinorVersion = true
                  protectedSettings = jsonencode({
                    script = lower(each.value.machine.osDisk.type) == "windows" ? null : base64encode(
                      templatefile(each.value.machine.extension.custom.fileName, merge(each.value.machine.extension.custom.parameters, {
                        fileSystem = local.fileSystemLinux
                      }))
                    )
                    commandToExecute = lower(each.value.machine.osDisk.type) == "windows" ? "PowerShell -ExecutionPolicy Unrestricted -EncodedCommand ${textencodebase64(
                      templatefile(each.value.machine.extension.custom.fileName, merge(each.value.machine.extension.custom.parameters, {
                        fileSystem      = local.fileSystemWindows
                        activeDirectory = each.value.activeDirectory
                      })), "UTF-16LE"
                    )}" : null
                  })
                }
              }
            ]
          }
        }
      }
      regularPriorityProfile = {
        allocationStrategy = each.value.machine.priority.standard.allocationStrategy
        minCapacity        = each.value.machine.priority.standard.capacityMinimum
        capacity           = each.value.machine.priority.standard.capacityTarget
      }
      spotPriorityProfile = {
        allocationStrategy = each.value.machine.priority.spot.allocationStrategy
        evictionPolicy     = each.value.machine.priority.spot.evictionPolicy
        capacity           = each.value.machine.priority.spot.capacityTarget
        maintain           = each.value.machine.priority.spot.capacityMaintain.enable
      }
      vmSizesProfile = each.value.machine.sizes
    }
  }
  schema_validation_enabled = false
}
