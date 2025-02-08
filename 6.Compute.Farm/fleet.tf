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
        versionId         = string
        galleryName       = string
        definitionName    = string
        resourceGroupName = string
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
            publisher = lower(computeFleet.machine.image.plan.publisher != "" ? computeFleet.machine.image.plan.publisher : module.global.linux.publisher)
            product   = lower(computeFleet.machine.image.plan.product != "" ? computeFleet.machine.image.plan.product : module.global.linux.offer)
            name      = lower(computeFleet.machine.image.plan.name != "" ? computeFleet.machine.image.plan.name : module.global.linux.sku)
          }
        })
        adminLogin = merge(computeFleet.machine.adminLogin, {
          userName     = computeFleet.machine.adminLogin.userName != "" ? computeFleet.machine.adminLogin.userName : data.azurerm_key_vault_secret.admin_username.value
          userPassword = computeFleet.machine.adminLogin.userPassword != "" ? computeFleet.machine.adminLogin.userPassword : data.azurerm_key_vault_secret.admin_password.value
          sshKeyPublic = computeFleet.machine.adminLogin.sshKeyPublic != "" ? computeFleet.machine.adminLogin.sshKeyPublic : data.azurerm_key_vault_secret.ssh_key_public.value
        })
      })
      network = merge(computeFleet.network, {
        subnetId = "${computeFleet.network.locationExtended.enable ? data.azurerm_virtual_network.studio_extended.id : data.azurerm_virtual_network.studio.id}/subnets/${var.existingNetwork.enable ? var.existingNetwork.subnetName : computeFleet.network.subnetName}"
      })
      activeDirectory = merge(var.activeDirectory, {
        adminUsername = var.activeDirectory.adminUsername != "" ? var.activeDirectory.adminUsername : data.azurerm_key_vault_secret.admin_username.value
        adminPassword = var.activeDirectory.adminPassword != "" ? var.activeDirectory.adminPassword : data.azurerm_key_vault_secret.admin_password.value
      })
    }) if computeFleet.enable
  ]
}

# resource azurerm_role_assignment managed_identity_operator {
#   role_definition_name = "Managed Identity Operator" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/identity#managed-identity-operator
#   principal_id         = "abed6e1f-d97c-4920-b0e2-3578e6d46549" # DEV-fleetAadApp
#   scope                = data.azurerm_user_assigned_identity.studio.id
# }

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
    # dynamic plan {
    #   for_each = each.value.machine.image.plan.publisher != "" ? [1] : []
    #   content {
    #     publisher = each.value.machine.image.plan.publisher
    #     product   = each.value.machine.image.plan.product
    #     name      = each.value.machine.image.plan.name
    #   }
    # }
    # plan = {
    #   publisher = each.value.machine.image.plan.publisher
    #   product   = each.value.machine.image.plan.product
    #   name      = each.value.machine.image.plan.name
    # }
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
                  typeHandlerVersion      = lower(each.value.machine.osDisk.type) == "windows" ? module.global.version.script_extension_windows : module.global.version.script_extension_linux
                  autoUpgradeMinorVersion = true
                  protectedSettings = jsonencode({
                    script = lower(each.value.machine.osDisk.type) == "windows" ? null : base64encode(
                      templatefile(each.value.machine.extension.custom.fileName, merge(each.value.machine.extension.custom.parameters, {
                        fileSystem = module.global.fileSystem.linux
                      }))
                    )
                    commandToExecute = lower(each.value.machine.osDisk.type) == "windows" ? "PowerShell -ExecutionPolicy Unrestricted -EncodedCommand ${textencodebase64(
                      templatefile(each.value.machine.extension.custom.fileName, merge(each.value.machine.extension.custom.parameters, {
                        fileSystem      = module.global.fileSystem.windows
                        activeDirectory = each.value.activeDirectory
                      })), "UTF-16LE"
                    )}" : null
                  })
                }
              }
            ]
          }
          scheduledEventsProfile = {
            terminateNotificationProfile = {
              enable           = each.value.machine.extension.custom.parameters.terminateNotification.enable
              notBeforeTimeout = each.value.machine.extension.custom.parameters.terminateNotification.delayTimeout
            }
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
