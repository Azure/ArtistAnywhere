######################################################################################################
# Hammerspace (https://azuremarketplace.microsoft.com/marketplace/apps/hammerspace.hammerspace-byol) #
######################################################################################################

resource azurerm_virtual_machine_extension node {
  for_each = {
    for node in concat(local.hsMetadataNodes, local.hsDataNodes) : node.machine.name => node
  }
  name                       = "Custom"
  type                       = "CustomScript"
  publisher                  = "Microsoft.Azure.Extensions"
  type_handler_version       = "2.1"
  automatic_upgrade_enabled  = false
  auto_upgrade_minor_version = true
  virtual_machine_id         = "${data.azurerm_resource_group.hammerspace.id}/providers/Microsoft.Compute/virtualMachines/${each.value.machine.name}"
  protected_settings = jsonencode({
    script = base64encode(
      templatefile("${path.module}/node.sh", {
        adminPassword = each.value.machine.adminLogin.userPassword
      })
    )
  })
  depends_on = [
    azurerm_virtual_machine_data_disk_attachment.metadata,
    azurerm_virtual_machine_data_disk_attachment.data
  ]
}

resource terraform_data cluster_init {
  provisioner local-exec {
    command = "az vm extension set --resource-group ${data.azurerm_resource_group.hammerspace.name} --vm-name ${local.hsMetadataNodes[0].machine.name} --name CustomScript --publisher Microsoft.Azure.Extensions --protected-settings ${jsonencode({script = base64encode(templatefile("${path.module}/cluster.init.sh", {activeDirectory = var.activeDirectory}))})}"
  }
  depends_on = [
    azurerm_virtual_machine_extension.node
  ]
}

resource terraform_data cluster_config {
  provisioner local-exec {
    command = "az vm extension set --resource-group ${data.azurerm_resource_group.hammerspace.name} --vm-name ${local.hsMetadataNodes[0].machine.name} --name CustomScript --publisher Microsoft.Azure.Extensions --protected-settings ${jsonencode({script = base64encode(templatefile("${path.module}/cluster.config.sh", {storageAccounts = var.hammerspace.storageAccounts, shares = var.hammerspace.shares, volumes = var.hammerspace.volumes, volumeGroups = var.hammerspace.volumeGroups}))})}"
  }
  depends_on = [
    terraform_data.cluster_init
  ]
}

##############################################################################################
# Proximity Placement Group (https://learn.microsoft.com/azure/virtual-machines/co-location) #
##############################################################################################

resource azurerm_proximity_placement_group hammerspace {
  count               = var.hammerspace.proximityPlacementGroup.enable ? 1 : 0
  name                = var.hammerspace.namePrefix
  resource_group_name = data.azurerm_resource_group.hammerspace.name
  location            = data.azurerm_resource_group.hammerspace.location
}

############################################################################
# Private DNS (https://learn.microsoft.com/azure/dns/private-dns-overview) #
############################################################################

resource azurerm_private_dns_a_record hammerspace {
  name                = "${lower(var.dnsRecord.name)}-hs"
  resource_group_name = var.virtualNetwork.privateDNS.resourceGroupName
  zone_name           = var.virtualNetwork.privateDNS.zoneName
  ttl                 = var.dnsRecord.ttlSeconds
  records = var.dnsRecord.metadataTier.enable ? local.hsHighAvailability ? [
    azurerm_lb.metadata[0].frontend_ip_configuration[0].private_ip_address
  ] : [
    for node in local.hsMetadataNodes : azurerm_linux_virtual_machine.metadata[node.machine.name].private_ip_address
  ] : [
    for node in local.hsDataNodes : azurerm_linux_virtual_machine.data[node.machine.name].private_ip_address
  ]
}

output privateDNS {
  value = {
    fqdn    = azurerm_private_dns_a_record.hammerspace.fqdn
    records = azurerm_private_dns_a_record.hammerspace.records
    metadataTier = {
      enable = var.dnsRecord.metadataTier.enable
    }
  }
}
