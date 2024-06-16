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
    })
    network = object({
      subnetName = string
      acceleration = object({
        enable = bool
      })
      locationEdge = object({
        enable = bool
      })
    })
    adminLogin = object({
      userName     = string
      userPassword = string
      sshPublicKey = string
    })
  }))
}

data local_file virtual_network_provider {
  filename = local.vnetProvider
  depends_on = [
    terraform_data.virtual_network_provider
  ]
}

locals {
  vnetProvider = "compute.fleet.vnet.json"
  computeFleets = [
    for computeFleet in var.computeFleets : merge(computeFleet, {
      resourceLocation = {
        regionName = module.global.resourceLocation.edgeZone.enable ? module.global.resourceLocation.edgeZone.regionName : module.global.resourceLocation.regionName
        edgeZone   = module.global.resourceLocation.edgeZone.enable ? module.global.resourceLocation.edgeZone.name : null
      }
      machine = merge(computeFleet.machine, {
        image = merge(computeFleet.machine.image, {
          plan = {
            publisher = try(data.terraform_remote_state.image.outputs.linuxPlan.publisher, computeFleet.machine.image.plan.publisher)
            product   = try(data.terraform_remote_state.image.outputs.linuxPlan.offer, computeFleet.machine.image.plan.product)
            name      = try(data.terraform_remote_state.image.outputs.linuxPlan.sku, computeFleet.machine.image.plan.name)
          }
        })
      })
      network = merge(computeFleet.network, {
        subnetId = "${computeFleet.network.locationEdge.enable ? data.azurerm_virtual_network.studio_edge.id : data.azurerm_virtual_network.studio_region.id}/subnets/${var.existingNetwork.enable ? var.existingNetwork.subnetName : computeFleet.network.subnetName}"
      })
      adminLogin = merge(computeFleet.adminLogin, {
        userName     = computeFleet.adminLogin.userName != "" || !module.global.keyVault.enable ? computeFleet.adminLogin.userName : data.azurerm_key_vault_secret.admin_username[0].value
        userPassword = computeFleet.adminLogin.userPassword != "" || !module.global.keyVault.enable ? computeFleet.adminLogin.userPassword : data.azurerm_key_vault_secret.admin_password[0].value
      })
      activeDirectory = merge(var.activeDirectory, {
        adminUsername = var.activeDirectory.adminUsername != "" || !module.global.keyVault.enable ? var.activeDirectory.adminUsername : data.azurerm_key_vault_secret.admin_username[0].value
        adminPassword = var.activeDirectory.adminPassword != "" || !module.global.keyVault.enable ? var.activeDirectory.adminPassword : data.azurerm_key_vault_secret.admin_password[0].value
      })
    }) if computeFleet.enable
  ]
}

resource terraform_data virtual_network_provider {
  provisioner local-exec {
    command = "az provider show --namespace Microsoft.Network --query resourceTypes[?resourceType=='virtualNetworks'] > ${local.vnetProvider}"
  }
}

resource azapi_resource fleet {
  for_each = {
    for computeFleet in local.computeFleets : computeFleet.name => computeFleet
  }
  name      = each.value.name
  type      = "Microsoft.AzureFleet/fleets@2024-05-01-preview"
  parent_id = azurerm_resource_group.farm.id
  location  = azurerm_resource_group.farm.location
  body = jsonencode({
    properties = {
      computeProfile = {
        baseVirtualMachineProfile = {
          storageProfile = {
            imageReference = {
              id = "/subscriptions/${local.subscriptionId.computeGallery}/resourceGroups/${each.value.machine.image.resourceGroupName}/providers/Microsoft.Compute/galleries/${each.value.machine.image.galleryName}/images/${each.value.machine.image.definitionName}/versions/${each.value.machine.image.versionId}"
            }
          }
          osProfile = {
            computerNamePrefix = each.value.machine.namePrefix != "" ? each.value.machine.namePrefix : each.value.name
            adminUsername      = each.value.adminLogin.userName
            adminPassword      = each.value.adminLogin.userPassword
          }
          networkProfile = {
            networkApiVersion = jsondecode(data.local_file.virtual_network_provider.content)[0].apiVersions[0]
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
  })
  schema_validation_enabled = false
  depends_on = [
    data.local_file.virtual_network_provider
  ]
}
