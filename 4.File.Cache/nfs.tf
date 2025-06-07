##################################################################
# Boost (https://learn.microsoft.com/azure/azure-boost/overview) #
##################################################################

variable nfsCache {
  type = object({
    enable = bool
    name   = string
    machine = object({
      size   = string
      count  = number
      prefix = string
      image = object({
        publisher = string
        product   = string
        name      = string
        version   = string
      })
      osDisk = object({
        storageType = string
        cachingMode = string
        sizeGB      = number
        ephemeral = object({
          enable    = bool
          placement = string
        })
      })
      dataDisk = object({
        enable      = bool
        storageType = string
        cachingMode = string
        sizeGB      = number
        count       = number
      })
      adminLogin = object({
        userName     = string
        userPassword = string
        sshKeyPublic = string
        passwordAuth = object({
          disable = bool
        })
      })
      extension = object({
        custom = object({
          enable   = bool
          name     = string
          fileName = string
          parameters = object({
            storageMounts = list(object({
              enable      = bool
              type        = string
              path        = string
              source      = string
              options     = string
              description = string
              permissions = object({
                enable     = bool
                recursive  = bool
                octalValue = number
              })
            }))
            cacheMetrics = object({
              intervalSeconds = number
              nodeExportsPort = number
              customStatsPort = number
            })
          })
        })
      })
    })
    network = object({
      acceleration = object({
        enable = bool
      })
    })
  })
}

data azurerm_virtual_machine_scale_set cache {
  count               = var.nfsCache.enable ? 1 : 0
  name                = azurerm_orchestrated_virtual_machine_scale_set.cache[0].name
  resource_group_name = azurerm_orchestrated_virtual_machine_scale_set.cache[0].resource_group_name
}

locals {
  nfsCache = var.nfsCache.enable ? merge(var.nfsCache, {
    machine = merge(var.nfsCache.machine, {
      adminLogin = merge(var.nfsCache.machine.adminLogin, {
        userName     = var.nfsCache.machine.adminLogin.userName != "" ? var.nfsCache.machine.adminLogin.userName : data.azurerm_key_vault_secret.admin_username.value
        userPassword = var.nfsCache.machine.adminLogin.userPassword != "" ? var.nfsCache.machine.adminLogin.userPassword : data.azurerm_key_vault_secret.admin_password.value
        sshKeyPublic = var.nfsCache.machine.adminLogin.sshKeyPublic != "" ? var.nfsCache.machine.adminLogin.sshKeyPublic : data.azurerm_key_vault_secret.ssh_key_public.value
      })
    })
  }) : null
  nfsCacheDataDisks = var.nfsCache.enable ? flatten([
    for iVirtualMachine in range(var.nfsCache.machine.count) : [
      for iDataDisk in range(var.nfsCache.machine.dataDisk.count) : {
        key         = "${var.nfsCache.name}_VM_${iVirtualMachine + 1}_DataDisk_${iDataDisk + 1}"
        name        = "${data.azurerm_virtual_machine_scale_set.cache[0].instances[iVirtualMachine].name}_DataDisk_${iDataDisk + 1}"
        machineName = data.azurerm_virtual_machine_scale_set.cache[0].instances[iVirtualMachine].name
        cachingMode = var.nfsCache.machine.dataDisk.cachingMode
        lun         = iDataDisk
      }
    ] if var.nfsCache.machine.dataDisk.enable
  ]) : null
}

resource azurerm_orchestrated_virtual_machine_scale_set cache {
  count                       = var.nfsCache.enable ? 1 : 0
  name                        = var.nfsCache.name
  resource_group_name         = azurerm_resource_group.cache.name
  location                    = azurerm_resource_group.cache.location
  sku_name                    = var.nfsCache.machine.size
  instances                   = var.nfsCache.machine.count
  platform_fault_domain_count = 1
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.main.id
    ]
  }
  network_interface {
    name    = var.nfsCache.name
    primary = true
    ip_configuration {
      name      = "ipConfig"
      primary   = true
      subnet_id = data.azurerm_subnet.cache.id
    }
    enable_accelerated_networking = var.nfsCache.network.acceleration.enable
  }
  os_profile {
    custom_data = base64encode(templatefile("nfs.py", {
      metricsIntervalSeconds = var.nfsCache.machine.extension.custom.parameters.cacheMetrics.intervalSeconds
      metricsCustomStatsPort = var.nfsCache.machine.extension.custom.parameters.cacheMetrics.customStatsPort
    }))
    linux_configuration {
      computer_name_prefix            = var.nfsCache.machine.prefix != "" ? var.nfsCache.machine.prefix : null
      admin_username                  = local.nfsCache.machine.adminLogin.userName
      admin_password                  = local.nfsCache.machine.adminLogin.userPassword
      disable_password_authentication = local.nfsCache.machine.adminLogin.passwordAuth.disable
      dynamic admin_ssh_key {
        for_each = local.nfsCache.machine.adminLogin.sshKeyPublic != "" ? [1] : []
        content {
          username   = local.nfsCache.machine.adminLogin.userName
          public_key = local.nfsCache.machine.adminLogin.sshKeyPublic
        }
      }
    }
  }
  os_disk {
    storage_account_type = var.nfsCache.machine.osDisk.storageType
    caching              = var.nfsCache.machine.osDisk.cachingMode
    disk_size_gb         = var.nfsCache.machine.osDisk.sizeGB > 0 ? var.nfsCache.machine.osDisk.sizeGB : null
    dynamic diff_disk_settings {
      for_each = var.nfsCache.machine.osDisk.ephemeral.enable ? [1] : []
      content {
        option    = "Local"
        placement = var.nfsCache.machine.osDisk.ephemeral.placement
      }
    }
  }
  source_image_reference {
    publisher = local.nfsCache.machine.image.publisher
    offer     = local.nfsCache.machine.image.product
    sku       = local.nfsCache.machine.image.name
    version   = local.nfsCache.machine.image.version
  }
  dynamic additional_capabilities {
    for_each = var.nfsCache.machine.dataDisk.enable ? [1] : []
    content {
      ultra_ssd_enabled = lower(var.nfsCache.machine.dataDisk.storageType) == "ultrassd_lrs"
    }
  }
}

resource azurerm_managed_disk cache {
  for_each = {
    for dataDisk in var.nfsCache.enable ? local.nfsCacheDataDisks : [] : dataDisk.key => dataDisk
  }
  name                          = each.value.name
  resource_group_name           = azurerm_resource_group.cache.name
  location                      = azurerm_resource_group.cache.location
  storage_account_type          = var.nfsCache.machine.dataDisk.storageType
  disk_size_gb                  = var.nfsCache.machine.dataDisk.sizeGB
  create_option                 = "Empty"
  public_network_access_enabled = false
}

resource azurerm_virtual_machine_data_disk_attachment cache {
  for_each = {
    for dataDisk in var.nfsCache.enable ? local.nfsCacheDataDisks : [] : dataDisk.key => dataDisk
  }
  virtual_machine_id = "${azurerm_resource_group.cache.id}/providers/Microsoft.Compute/virtualMachines/${each.value.machineName}"
  managed_disk_id    = "${azurerm_resource_group.cache.id}/providers/Microsoft.Compute/disks/${each.value.name}"
  caching            = each.value.cachingMode
  lun                = each.value.lun
  depends_on = [
    azurerm_orchestrated_virtual_machine_scale_set.cache,
    azurerm_managed_disk.cache,
  ]
}

resource azurerm_virtual_machine_extension cache {
  count                      = var.nfsCache.enable ? var.nfsCache.machine.count : 0
  name                       = var.nfsCache.machine.extension.custom.name
  type                       = "CustomScript"
  publisher                  = "Microsoft.Azure.Extensions"
  type_handler_version       = data.azurerm_app_configuration_keys.main.items[index(data.azurerm_app_configuration_keys.main.items[*].key, data.terraform_remote_state.foundation.outputs.appConfig.key.scriptExtensionLinux)].value
  virtual_machine_id         = "${azurerm_resource_group.cache.id}/providers/Microsoft.Compute/virtualMachines/${data.azurerm_virtual_machine_scale_set.cache[0].instances[count.index].name}"
  automatic_upgrade_enabled  = false
  auto_upgrade_minor_version = true
  protected_settings = jsonencode({
    script = base64encode(
      templatefile(var.nfsCache.machine.extension.custom.fileName, merge(var.nfsCache.machine.extension.custom.parameters, {
        dataDiskCount          = var.nfsCache.machine.dataDisk.count
        metricsIntervalSeconds = var.nfsCache.machine.extension.custom.parameters.cacheMetrics.intervalSeconds
        metricsNodeExportsPort = var.nfsCache.machine.extension.custom.parameters.cacheMetrics.nodeExportsPort
        metricsCustomStatsPort = var.nfsCache.machine.extension.custom.parameters.cacheMetrics.customStatsPort
        metricsIngestionUrl    = "${data.azurerm_monitor_data_collection_endpoint.main.metrics_ingestion_endpoint}/dataCollectionRules/${data.azurerm_monitor_data_collection_rule.main.immutable_id}/streams/Microsoft-PrometheusMetrics/api/v1/write?api-version=${var.monitorWorkspace.metricsIngestion.apiVersion}"
        exportAddressSpace     = data.azurerm_virtual_network.main.address_space[0]
        userIdentityClientId   = data.azurerm_user_assigned_identity.main.client_id
      }))
    )
  })
  depends_on = [
    azurerm_virtual_machine_data_disk_attachment.cache
  ]
}

############################################################################
# Private DNS (https://learn.microsoft.com/azure/dns/private-dns-overview) #
############################################################################

resource azurerm_private_dns_a_record cache_nfs {
  count               = var.nfsCache.enable ? 1 : 0
  name                = lower(var.dnsRecord.name)
  resource_group_name = var.virtualNetwork.privateDNS.resourceGroupName
  zone_name           = var.virtualNetwork.privateDNS.zoneName
  records             = data.azurerm_virtual_machine_scale_set.cache[0].instances[*].private_ip_address
  ttl                 = var.dnsRecord.ttlSeconds
}
