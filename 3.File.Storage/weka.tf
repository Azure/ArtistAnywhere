#######################################################################################################
# Weka (https://azuremarketplace.microsoft.com/marketplace/apps/weka1652213882079.weka_data_platform) #
#######################################################################################################

variable weka {
  type = object({
    enable   = bool
    version  = string
    apiToken = string
    name = object({
      resource = string
      display  = string
    })
    machine = object({
      size  = string
      count = number
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
        storageType = string
        cachingType = string
        sizeGB      = number
      })
      dataDisk = object({
        storageType = string
        cachingType = string
        sizeGB      = number
      })
      adminLogin = object({
        userName      = string
        userPassword  = string
        sshKeyPublic  = string
        sshKeyPrivate = string
        passwordAuth = object({
          disable = bool
        })
      })
      terminateNotification = object({
        enable       = bool
        delayTimeout = string
      })
    })
    network = object({
      acceleration = object({
        enable = bool
      })
      dnsRecord = object({
        name       = string
        ttlSeconds = number
      })
    })
    objectTier = object({
      percent = number
      storage = object({
        accountName   = string
        accountKey    = string
        containerName = string
      })
    })
    fileSystem = object({
      name         = string
      groupName    = string
      autoScale    = bool
      authRequired = bool
      loadFiles    = bool
    })
    dataProtection = object({
      stripeWidth = number
      parityLevel = number
      hotSpare    = number
    })
    healthExtension = object({
      protocol    = string
      port        = number
      requestPath = string
    })
    license = object({
      key = string
      payGo = object({
        planId    = string
        secretKey = string
      })
    })
    supportUrl = string
  })
}

data azurerm_storage_account blob {
  count               = var.weka.enable ? 1 : 0
  name                = local.nfsStorageAccounts[0].name
  resource_group_name = local.nfsStorageAccounts[0].resource_group_name
  depends_on = [
    azurerm_storage_account.studio
  ]
}

data azurerm_virtual_machine_scale_set weka {
  count               = var.weka.enable ? 1 : 0
  name                = azurerm_linux_virtual_machine_scale_set.weka[0].name
  resource_group_name = azurerm_linux_virtual_machine_scale_set.weka[0].resource_group_name
}

locals {
  weka = merge(var.weka, {
    machine = merge(var.weka.machine, {
      image = merge(var.weka.machine.image, {
        plan = {
          publisher = try(data.terraform_remote_state.image.outputs.linuxPlan.publisher, var.weka.machine.image.plan.publisher)
          product   = try(data.terraform_remote_state.image.outputs.linuxPlan.offer, var.weka.machine.image.plan.product)
          name      = try(data.terraform_remote_state.image.outputs.linuxPlan.sku, var.weka.machine.image.plan.name)
        }
      })
      adminLogin = {
        userName      = var.weka.machine.adminLogin.userName != "" ? var.weka.machine.adminLogin.userName : data.azurerm_key_vault_secret.admin_username.value
        userPassword  = var.weka.machine.adminLogin.userPassword != "" ? var.weka.machine.adminLogin.userPassword : data.azurerm_key_vault_secret.admin_password.value
        sshKeyPublic  = var.weka.machine.adminLogin.sshKeyPublic != "" ? var.weka.machine.adminLogin.sshKeyPublic : data.azurerm_key_vault_secret.ssh_key_public.value
        sshKeyPrivate = var.weka.machine.adminLogin.sshKeyPrivate != "" ? var.weka.machine.adminLogin.sshKeyPrivate : data.azurerm_key_vault_secret.ssh_key_private.value
      }
    })
    objectTier = merge(var.weka.objectTier, {
      storage = {
        accountName   = var.weka.objectTier.storage.accountName != "" || !var.weka.enable ? var.weka.objectTier.storage.accountName : data.azurerm_storage_account.blob[0].name
        accountKey    = var.weka.objectTier.storage.accountKey != "" || !var.weka.enable ? var.weka.objectTier.storage.accountKey : data.azurerm_storage_account.blob[0].primary_access_key
        containerName = var.weka.objectTier.storage.containerName != "" ? var.weka.objectTier.storage.containerName : "weka"
      }
    })
  })
  wekaMachineSize = trimsuffix(trimsuffix(trimprefix(var.weka.machine.size, "Standard_"), "as_v3"), "s_v3")
  wekaMachineSpec = jsonencode(local.wekaMachineSpecs[local.wekaMachineSize])
  wekaMachineSpecs = {
    L8 = {
      nvmeDisks     = 1
      coreDrives    = 1
      coreCompute   = 1
      coreFrontend  = 1
      networkCards  = 4
      computeMemory = "31GB"
    }
    L16 = {
      nvmeDisks     = 2
      coreDrives    = 2
      coreCompute   = 4
      coreFrontend  = 1
      networkCards  = 8
      computeMemory = "72GB"
    }
    L32 = {
      nvmeDisks     = 4
      coreDrives    = 2
      coreCompute   = 4
      coreFrontend  = 1
      networkCards  = 8
      computeMemory = "189GB"
    }
    L48 = {
      nvmeDisks     = 6
      coreDrives    = 3
      coreCompute   = 3
      coreFrontend  = 1
      networkCards  = 8
      computeMemory = "306GB"
    }
    L64 = {
      nvmeDisks     = 8
      coreDrives    = 2
      coreCompute   = 4
      coreFrontend  = 1
      networkCards  = 8
      computeMemory = "418GB"
    }
  }
  wekaCoreIdsScript    = "${local.binDirectory}/weka-core-ids.sh"
  wekaDriveDisksScript = "${local.binDirectory}/weka-drive-disks.sh"
  wekaFileSystemScript = "${local.binDirectory}/weka-file-system.sh"
  binDirectory = "/usr/local/bin"
}

resource azurerm_resource_group weka {
  count    = var.weka.enable ? 1 : 0
  name     = "${var.resourceGroupName}.Weka"
  location = local.regionName
  tags = {
    AAA = basename(path.cwd)
  }
}

resource azurerm_role_assignment weka_private_dns_zone_contributor {
  count                = var.weka.enable ? 1 : 0
  role_definition_name = "Private DNS Zone Contributor" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/networking#private-dns-zone-contributor
  principal_id         = data.azurerm_user_assigned_identity.studio.principal_id
  scope                = "/subscriptions/${data.azurerm_client_config.studio.subscription_id}/resourceGroups/${data.azurerm_virtual_network.studio_region.resource_group_name}"
}

resource time_sleep weka_rbac {
  count           = var.weka.enable ? 1 : 0
  create_duration = "30s"
  depends_on = [
    azurerm_role_assignment.weka_virtual_machine_contributor,
    azurerm_role_assignment.weka_private_dns_zone_contributor
  ]
}

resource azurerm_proximity_placement_group weka {
  count               = var.weka.enable ? 1 : 0
  name                = var.weka.name.resource
  resource_group_name = azurerm_resource_group.weka[0].name
  location            = azurerm_resource_group.weka[0].location
}

resource azurerm_storage_container weka {
  count                = var.weka.enable ? 1 : 0
  name                 = local.weka.objectTier.storage.containerName
  storage_account_name = local.weka.objectTier.storage.accountName
}

resource azurerm_linux_virtual_machine_scale_set weka {
  count                           = var.weka.enable ? 1 : 0
  name                            = var.weka.name.resource
  resource_group_name             = azurerm_resource_group.weka[0].name
  location                        = azurerm_resource_group.weka[0].location
  sku                             = var.weka.machine.size
  instances                       = var.weka.machine.count
  source_image_id                 = "/subscriptions/${data.azurerm_client_config.studio.subscription_id}/resourceGroups/${var.weka.machine.image.resourceGroupName}/providers/Microsoft.Compute/galleries/${var.weka.machine.image.galleryName}/images/${var.weka.machine.image.definitionName}/versions/${var.weka.machine.image.versionId}"
  admin_username                  = local.weka.machine.adminLogin.userName
  admin_password                  = local.weka.machine.adminLogin.userPassword
  disable_password_authentication = var.weka.machine.adminLogin.passwordAuth.disable
  proximity_placement_group_id    = azurerm_proximity_placement_group.weka[0].id
  single_placement_group          = false
  overprovision                   = false
  custom_data = base64encode(templatefile("terminate.sh", {
    wekaClusterName      = var.weka.name.resource
    wekaAdminPassword    = local.weka.machine.adminLogin.userPassword
    dnsResourceGroupName = data.azurerm_private_dns_zone.studio.resource_group_name
    dnsZoneName          = data.azurerm_private_dns_zone.studio.name
    dnsRecordName        = var.weka.network.dnsRecord.name
    binDirectory         = local.binDirectory
  }))
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  network_interface {
    name    = "nic1"
    primary = true
    ip_configuration {
      name      = "ipConfig"
      primary   = true
      subnet_id = data.azurerm_subnet.storage_region.id
    }
    enable_accelerated_networking = var.weka.network.acceleration.enable
  }
  os_disk {
    storage_account_type = var.weka.machine.osDisk.storageType
    caching              = var.weka.machine.osDisk.cachingType
    disk_size_gb         = var.weka.machine.osDisk.sizeGB > 0 ? var.weka.machine.osDisk.sizeGB : null
  }
  data_disk {
    storage_account_type = var.weka.machine.dataDisk.storageType
    caching              = var.weka.machine.dataDisk.cachingType
    disk_size_gb         = var.weka.machine.dataDisk.sizeGB
    create_option        = "Empty"
    lun                  = 0
  }
  termination_notification {
    enabled = var.weka.machine.terminateNotification.enable
    timeout = var.weka.machine.terminateNotification.delayTimeout
  }
  extension {
    name                       = "Health"
    type                       = "ApplicationHealthLinux"
    publisher                  = "Microsoft.ManagedServices"
    type_handler_version       = "1.0"
    automatic_upgrade_enabled  = true
    auto_upgrade_minor_version = true
    settings = jsonencode({
      protocol    = var.weka.healthExtension.protocol
      port        = var.weka.healthExtension.port
      requestPath = var.weka.healthExtension.requestPath
    })
  }
  extension {
    name                       = "Initialize"
    type                       = "CustomScript"
    publisher                  = "Microsoft.Azure.Extensions"
    type_handler_version       = "2.1"
    automatic_upgrade_enabled  = false
    auto_upgrade_minor_version = true
    protected_settings = jsonencode({
      script = base64encode(
        templatefile("weka.sh", {
          wekaVersion               = var.weka.version
          wekaApiToken              = var.weka.apiToken
          wekaClusterName           = var.weka.name.resource
          wekaDataDiskSize          = var.weka.machine.dataDisk.sizeGB
          wekaMachineSpec           = local.wekaMachineSpec
          wekaCoreIdsScript         = local.wekaCoreIdsScript
          wekaDriveDisksScript      = local.wekaDriveDisksScript
          wekaFileSystemScript      = local.wekaFileSystemScript
          wekaFileSystemName        = var.weka.fileSystem.name
          wekaFileSystemAutoScale   = var.weka.fileSystem.autoScale
          wekaObjectTierPercent     = local.weka.objectTier.percent
          wekaTerminateNotification = var.weka.machine.terminateNotification
          wekaAdminPassword         = local.weka.machine.adminLogin.userPassword
          wekaResourceGroupName     = azurerm_resource_group.weka[0].name
          dnsResourceGroupName      = data.azurerm_private_dns_zone.studio.resource_group_name
          dnsZoneName               = data.azurerm_private_dns_zone.studio.name
          dnsRecordName             = var.weka.network.dnsRecord.name
          binDirectory              = local.binDirectory
        })
      )
    })
    provision_after_extensions = [
      "Health"
    ]
  }
  dynamic plan {
    for_each = local.weka.machine.image.plan.publisher != "" ? [1] : []
    content {
      publisher = local.weka.machine.image.plan.publisher
      product   = local.weka.machine.image.plan.product
      name      = local.weka.machine.image.plan.name
    }
  }
  dynamic admin_ssh_key {
    for_each = local.weka.machine.adminLogin.sshKeyPublic != "" ? [1] : []
    content {
      username   = local.weka.machine.adminLogin.userName
      public_key = local.weka.machine.adminLogin.sshKeyPublic
    }
  }
  depends_on = [
    time_sleep.weka_rbac
  ]
}

resource azurerm_private_dns_a_record weka_cluster {
  count               = var.weka.enable ? 1 : 0
  name                = var.weka.network.dnsRecord.name
  resource_group_name = data.azurerm_private_dns_zone.studio.resource_group_name
  zone_name           = data.azurerm_private_dns_zone.studio.name
  records             = [for vmInstance in data.azurerm_virtual_machine_scale_set.weka[0].instances : vmInstance.private_ip_address]
  ttl                 = var.weka.network.dnsRecord.ttlSeconds
}

resource terraform_data weka_cluster_create {
  count = var.weka.enable ? 1 : 0
  connection {
    type     = "ssh"
    host     = data.azurerm_virtual_machine_scale_set.weka[0].instances[0].private_ip_address
    user     = local.weka.machine.adminLogin.userName
    password = local.weka.machine.adminLogin.userPassword
  }
  provisioner remote-exec {
    inline = [
      "machineSpec='${local.wekaMachineSpec}'",
      "source ${local.wekaDriveDisksScript}",
      "weka cluster create ${join(" ", data.azurerm_virtual_machine_scale_set.weka[0].instances[*].private_ip_address)} --admin-password ${local.weka.machine.adminLogin.userPassword} 2>&1 | tee weka-cluster-create.log",
      "weka user login admin ${local.weka.machine.adminLogin.userPassword}",
      "for (( i=0; i<${var.weka.machine.count}; i++ )); do",
      "  hostName=${azurerm_linux_virtual_machine_scale_set.weka[0].name}$(printf %06X $i)",
      "  weka cluster drive add $i --HOST $hostName $nvmeDisks 2>&1 | tee --append weka-cluster-drive-add-$hostName.log",
      "done"
    ]
  }
}

resource terraform_data weka_container_setup {
  count = var.weka.enable ? var.weka.machine.count : 0
  connection {
    type     = "ssh"
    host     = data.azurerm_virtual_machine_scale_set.weka[0].instances[count.index].private_ip_address
    user     = local.weka.machine.adminLogin.userName
    password = local.weka.machine.adminLogin.userPassword
  }
  provisioner remote-exec {
    inline = [
      "failureDomain=$(hostname)",
      "machineSpec='${local.wekaMachineSpec}'",
      "source ${local.wekaCoreIdsScript}",
      "joinIps=${join(",", [for vmInstance in data.azurerm_virtual_machine_scale_set.weka[0].instances : vmInstance.private_ip_address])}",
      "sudo weka local setup container --name compute0 --base-port 15000 --failure-domain $failureDomain --join-ips $joinIps --cores $coreCountCompute --compute-dedicated-cores $coreCountCompute --core-ids $coreIdsCompute --dedicate --memory $computeMemory --no-frontends &> weka-container-setup-compute0.log",
      "sudo weka local setup container --name frontend0 --base-port 16000 --failure-domain $failureDomain --join-ips $joinIps --cores $coreCountFrontend --frontend-dedicated-cores $coreCountFrontend --core-ids $coreIdsFrontend --dedicate &> weka-container-setup-frontend0.log"
    ]
  }
  depends_on = [
    terraform_data.weka_cluster_create
  ]
}

resource terraform_data weka_cluster_start {
  count = var.weka.enable ? 1 : 0
  connection {
    type     = "ssh"
    host     = data.azurerm_virtual_machine_scale_set.weka[0].instances[0].private_ip_address
    user     = local.weka.machine.adminLogin.userName
    password = local.weka.machine.adminLogin.userPassword
  }
  provisioner remote-exec {
    inline = [
      "weka cluster update --cluster-name='${var.weka.name.display}' --data-drives ${var.weka.dataProtection.stripeWidth} --parity-drives ${var.weka.dataProtection.parityLevel}",
      "weka cluster hot-spare ${var.weka.dataProtection.hotSpare}",
      "weka cloud enable ${var.weka.supportUrl != "" ? "--cloud-url=${var.weka.supportUrl}" : ""}",
      "if [ \"${var.weka.license.key}\" != \"\" ]; then",
      "  weka cluster license set ${var.weka.license.key} 2>&1 | tee weka-cluster-license.log",
      "elif [ \"${var.weka.license.payGo.planId}\" != \"\" ]; then",
      "  weka cluster license payg ${var.weka.license.payGo.planId} ${var.weka.license.payGo.secretKey} 2>&1 | tee weka-cluster-license.log",
      "fi",
      "weka cluster start-io"
    ]
  }
  depends_on = [
    terraform_data.weka_container_setup
  ]
}

resource terraform_data weka_file_system {
  count = var.weka.enable ? 1 : 0
  connection {
    type     = "ssh"
    host     = data.azurerm_virtual_machine_scale_set.weka[0].instances[0].private_ip_address
    user     = local.weka.machine.adminLogin.userName
    password = local.weka.machine.adminLogin.userPassword
  }
  provisioner remote-exec {
    inline = [
      "ioStatus=$(weka status --json | jq -r .io_status)",
      "if [ $ioStatus == STARTED ]; then",
      "  source ${local.wekaFileSystemScript}",
      "  fileSystemGroupName=${var.weka.fileSystem.groupName}",
      "  fileSystemAuthRequired=${var.weka.fileSystem.authRequired ? "yes" : "no"}",
      "  fileSystemContainerName=${local.weka.objectTier.storage.containerName}",
      "  weka fs tier s3 add $fileSystemContainerName --obs-type AZURE --hostname ${local.weka.objectTier.storage.accountName}.blob.core.windows.net --secret-key ${nonsensitive(local.weka.objectTier.storage.accountKey)} --access-key-id ${local.weka.objectTier.storage.accountName} --bucket ${local.weka.objectTier.storage.containerName} --protocol https --port 443",
      "  weka fs group create $fileSystemGroupName",
      "  weka fs create $fileSystemName $fileSystemGroupName \"$fileSystemTotalBytes\"B --obs-name $fileSystemContainerName --ssd-capacity \"$fileSystemDriveBytes\"B --auth-required $fileSystemAuthRequired",
      "fi",
      "weka status"
    ]
  }
  depends_on = [
    azurerm_storage_container.weka,
    terraform_data.weka_cluster_start
  ]
}

resource terraform_data weka_data {
  count = var.weka.enable && var.weka.fileSystem.loadFiles && var.dataLoad.enable ? 1 : 0
  connection {
    type        = "ssh"
    user        = local.weka.machine.adminLogin.userName
    private_key = local.weka.machine.adminLogin.sshKeyPrivate
    host        = data.azurerm_virtual_machine_scale_set.weka[0].instances[0].private_ip_address
   }
  provisioner remote-exec {
    inline = [
      "sudo weka agent install-agent",
      "mountPath=/mnt/${var.dataLoad.source.containerName}",
      "mkdir -p $mountPath",
      "sudo mount -t wekafs ${var.weka.fileSystem.name} $mountPath",
      "az storage copy --source-account-name ${var.dataLoad.source.accountName} --source-container ${var.dataLoad.source.containerName} --recursive --destination /mnt"
    ]
  }
  depends_on = [
    terraform_data.weka_file_system
  ]
}
