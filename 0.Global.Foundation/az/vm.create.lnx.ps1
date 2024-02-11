############
# Platform #
############

$regionName        = "WestUS2"
$nameSuffix        = "West"
$resourceGroupName = "AAA"
$virtualNetwork = @{
  subscriptionId    = az account show --query id --output tsv
  resourceGroupName = "ArtistAnywhere.Network.$nameSuffix"
  name              = "Studio-$nameSuffix"
  subnetName        = "Storage"
}
$virtualMachine = @{
  name     = "LnxPlatform"
  size     = "Standard_D8as_v5"
  imageId  = "AlmaLinux:AlmaLinux-x86_64:8-Gen2:Latest"
  subnetId = "/subscriptions/$($virtualNetwork.subscriptionId)/resourceGroups/$($virtualNetwork.resourceGroupName)/providers/Microsoft.Network/virtualNetworks/$($virtualNetwork.name)/subnets/$($virtualNetwork.subnetName)"
  osDisk = @{
    ephemeral = @{
      enable    = $false
      placement = "ResourceDisk"
    }
    caching = "None"
    sizeGB  = 0
  }
  adminLogin = @{
    username = "xadmin"
    password = "P@ssword1234"
  }
  securityType = "Standard"
}
az group create --name $resourceGroupName --location $regionName
if ($virtualMachine.osDisk.ephemeral.enable) {
  az vm create --resource-group $resourceGroupName --name $virtualMachine.name --size $virtualMachine.size --ephemeral-os-disk $virtualMachine.osDisk.ephemeral.enable --ephemeral-os-disk-placement $virtualMachine.osDisk.ephemeral.placement --os-disk-caching $virtualMachine.osDisk.caching --os-disk-size-gb $virtualMachine.osDisk.sizeGB --subnet $virtualMachine.subnetId --image $virtualMachine.imageId --admin-username $virtualMachine.adminLogin.username --admin-password $virtualMachine.adminLogin.password --public-ip-address '""' --nsg '""' --security-type $virtualMachine.securityType
} else {
  az vm create --resource-group $resourceGroupName --name $virtualMachine.name --size $virtualMachine.size --os-disk-caching $virtualMachine.osDisk.caching --os-disk-size-gb $virtualMachine.osDisk.sizeGB --subnet $virtualMachine.subnetId --image $virtualMachine.imageId --admin-username $virtualMachine.adminLogin.username --admin-password $virtualMachine.adminLogin.password --public-ip-address '""' --nsg '""' --security-type $virtualMachine.securityType
}

###########
# Storage #
###########

$regionName        = "WestUS2"
$nameSuffix        = "West"
$resourceGroupName = "AAA"
$virtualNetwork = @{
  subscriptionId    = az account show --query id --output tsv
  resourceGroupName = "ArtistAnywhere.Network.$nameSuffix"
  name              = "Studio-$nameSuffix"
  subnetName        = "Storage"
}
$virtualMachine = @{
  name     = "LnxStorage"
  size     = "Standard_L8s_v3"
  imageId  = "AlmaLinux:AlmaLinux-x86_64:8-Gen2:Latest"
  subnetId = "/subscriptions/$($virtualNetwork.subscriptionId)/resourceGroups/$($virtualNetwork.resourceGroupName)/providers/Microsoft.Network/virtualNetworks/$($virtualNetwork.name)/subnets/$($virtualNetwork.subnetName)"
  osDisk = @{
    ephemeral = @{
      enable    = $false
      placement = "ResourceDisk"
    }
    caching = "None"
    sizeGB  = 0
  }
  dataDisk = @{
    type    = "Premium_LRS"
    caching = "ReadWrite"
    sizeGB  = 512
    count   = 1
  }
  adminLogin = @{
    username = "xadmin"
    password = "P@ssword1234"
  }
  securityType = "Standard"
}
az group create --name $resourceGroupName --location $regionName
if ($virtualMachine.osDisk.ephemeral.enable) {
  az vm create --resource-group $resourceGroupName --name $virtualMachine.name --size $virtualMachine.size --ephemeral-os-disk $virtualMachine.osDisk.ephemeral.enable --ephemeral-os-disk-placement $virtualMachine.osDisk.ephemeral.placement --os-disk-caching $virtualMachine.osDisk.caching --os-disk-size-gb $virtualMachine.osDisk.sizeGB --subnet $virtualMachine.subnetId --image $virtualMachine.imageId --admin-username $virtualMachine.adminLogin.username --admin-password $virtualMachine.adminLogin.password --public-ip-address '""' --nsg '""' --security-type $virtualMachine.securityType
} else {
  az vm create --resource-group $resourceGroupName --name $virtualMachine.name --size $virtualMachine.size --os-disk-caching $virtualMachine.osDisk.caching --os-disk-size-gb $virtualMachine.osDisk.sizeGB --subnet $virtualMachine.subnetId --image $virtualMachine.imageId --admin-username $virtualMachine.adminLogin.username --admin-password $virtualMachine.adminLogin.password --public-ip-address '""' --nsg '""' --security-type $virtualMachine.securityType
}
for ($i = 1; $i -le $virtualMachine.dataDisk.count; $i++) {
  $dataDiskName = $virtualMachine.name + "_DataDisk_$i"
  az vm disk attach --resource-group $resourceGroupName --name $dataDiskName --sku $virtualMachine.dataDisk.type --caching $virtualMachine.dataDisk.caching --size-gb $virtualMachine.dataDisk.sizeGB --vm-name $virtualMachine.name --new
}

#################
# Job Scheduler #
#################

$regionName        = "WestUS2"
$nameSuffix        = "West"
$resourceGroupName = "AAA"
$virtualNetwork = @{
  subscriptionId    = az account show --query id --output tsv
  resourceGroupName = "ArtistAnywhere.Network.$nameSuffix"
  name              = "Studio-$nameSuffix"
  subnetName        = "Farm"
}
$virtualMachine = @{
  name     = "LnxScheduler"
  size     = "Standard_D8as_v5"
  imageId  = "AlmaLinux:AlmaLinux-x86_64:8-Gen2:Latest"
  subnetId = "/subscriptions/$($virtualNetwork.subscriptionId)/resourceGroups/$($virtualNetwork.resourceGroupName)/providers/Microsoft.Network/virtualNetworks/$($virtualNetwork.name)/subnets/$($virtualNetwork.subnetName)"
  adminLogin = @{
    username = "xadmin"
    password = "P@ssword1234"
  }
  osDisk = @{
    ephemeral = @{
      enable    = $false
      placement = "ResourceDisk"
    }
    caching = "ReadWrite"
    sizeGB  = 0
  }
  securityType = "Standard"
}
az group create --name $resourceGroupName --location $regionName
if ($virtualMachine.osDisk.ephemeral.enable) {
  az vm create --resource-group $resourceGroupName --name $virtualMachine.name --size $virtualMachine.size --ephemeral-os-disk $virtualMachine.osDisk.ephemeral.enable --ephemeral-os-disk-placement $virtualMachine.osDisk.ephemeral.placement --os-disk-caching $virtualMachine.osDisk.caching --os-disk-size-gb $virtualMachine.osDisk.sizeGB --subnet $virtualMachine.subnetId --image $virtualMachine.imageId --admin-username $virtualMachine.adminLogin.username --admin-password $virtualMachine.adminLogin.password --public-ip-address '""' --nsg '""' --security-type $virtualMachine.securityType
} else {
  az vm create --resource-group $resourceGroupName --name $virtualMachine.name --size $virtualMachine.size --os-disk-caching $virtualMachine.osDisk.caching --os-disk-size-gb $virtualMachine.osDisk.sizeGB --subnet $virtualMachine.subnetId --image $virtualMachine.imageId --admin-username $virtualMachine.adminLogin.username --admin-password $virtualMachine.adminLogin.password --public-ip-address '""' --nsg '""' --security-type $virtualMachine.securityType
}

###############
# Render Farm #
###############

$regionName        = "WestUS2"
$nameSuffix        = "West"
$resourceGroupName = "AAA"
$virtualNetwork = @{
  subscriptionId    = az account show --query id --output tsv
  resourceGroupName = "ArtistAnywhere.Network.$nameSuffix"
  name              = "Studio-$nameSuffix"
  subnetName        = "Farm"
}
$virtualMachine = @{
  name     = "LnxFarmC"
  size     = "Standard_HB120rs_v3"
  imageId  = "AlmaLinux:AlmaLinux-x86_64:8-Gen2:Latest"
  subnetId = "/subscriptions/$($virtualNetwork.subscriptionId)/resourceGroups/$($virtualNetwork.resourceGroupName)/providers/Microsoft.Network/virtualNetworks/$($virtualNetwork.name)/subnets/$($virtualNetwork.subnetName)"
  adminLogin = @{
    username = "xadmin"
    password = "P@ssword1234"
  }
  osDisk = @{
    ephemeral = @{
      enable    = $true
      placement = "ResourceDisk"
    }
    caching = "ReadOnly"
    sizeGB  = 360
  }
  securityType   = "Standard"
  priorityMode   = "Spot"
  evictionPolicy = "Delete"
  hibernation = @{
    enable = $false
  }
}
az group create --name $resourceGroupName --location $regionName
if ($virtualMachine.osDisk.ephemeral.enable) {
  az vm create --resource-group $resourceGroupName --name $virtualMachine.name --size $virtualMachine.size --ephemeral-os-disk $virtualMachine.osDisk.ephemeral.enable --ephemeral-os-disk-placement $virtualMachine.osDisk.ephemeral.placement --os-disk-caching $virtualMachine.osDisk.caching --os-disk-size-gb $virtualMachine.osDisk.sizeGB --subnet $virtualMachine.subnetId --image $virtualMachine.imageId --admin-username $virtualMachine.adminLogin.username --admin-password $virtualMachine.adminLogin.password --public-ip-address '""' --nsg '""' --security-type $virtualMachine.securityType --priority $virtualMachine.priorityMode --eviction-policy $virtualMachine.evictionPolicy --enable-hibernation $virtualMachine.hibernation.enable
} else {
  az vm create --resource-group $resourceGroupName --name $virtualMachine.name --size $virtualMachine.size --os-disk-caching $virtualMachine.osDisk.caching --os-disk-size-gb $virtualMachine.osDisk.sizeGB --subnet $virtualMachine.subnetId --image $virtualMachine.imageId --admin-username $virtualMachine.adminLogin.username --admin-password $virtualMachine.adminLogin.password --public-ip-address '""' --nsg '""' --security-type $virtualMachine.securityType --priority $virtualMachine.priorityMode --eviction-policy $virtualMachine.evictionPolicy --enable-hibernation $virtualMachine.hibernation.enable
}

$regionName        = "WestUS2"
$nameSuffix        = "West"
$resourceGroupName = "AAA"
$virtualNetwork = @{
  subscriptionId    = az account show --query id --output tsv
  resourceGroupName = "ArtistAnywhere.Network.$nameSuffix"
  name              = "Studio-$nameSuffix"
  subnetName        = "Farm"
}
$virtualMachine = @{
  name     = "LnxFarmG"
  size     = "Standard_NV36ads_A10_v5"
  imageId  = "AlmaLinux:AlmaLinux-x86_64:8-Gen2:Latest"
  subnetId = "/subscriptions/$($virtualNetwork.subscriptionId)/resourceGroups/$($virtualNetwork.resourceGroupName)/providers/Microsoft.Network/virtualNetworks/$($virtualNetwork.name)/subnets/$($virtualNetwork.subnetName)"
  adminLogin = @{
    username = "xadmin"
    password = "P@ssword1234"
  }
  osDisk = @{
    ephemeral = @{
      enable    = $true
      placement = "ResourceDisk"
    }
    caching = "ReadOnly"
    sizeGB  = 360
  }
  securityType   = "Standard"
  priorityMode   = "Spot"
  evictionPolicy = "Delete"
  hibernation = @{
    enable = $false
  }
}
az group create --name $resourceGroupName --location $regionName
if ($virtualMachine.osDisk.ephemeral.enable) {
  az vm create --resource-group $resourceGroupName --name $virtualMachine.name --size $virtualMachine.size --ephemeral-os-disk $virtualMachine.osDisk.ephemeral.enable --ephemeral-os-disk-placement $virtualMachine.osDisk.ephemeral.placement --os-disk-caching $virtualMachine.osDisk.caching --os-disk-size-gb $virtualMachine.osDisk.sizeGB --subnet $virtualMachine.subnetId --image $virtualMachine.imageId --admin-username $virtualMachine.adminLogin.username --admin-password $virtualMachine.adminLogin.password --public-ip-address '""' --nsg '""' --security-type $virtualMachine.securityType --priority $virtualMachine.priorityMode --eviction-policy $virtualMachine.evictionPolicy --enable-hibernation $virtualMachine.hibernation.enable
} else {
  az vm create --resource-group $resourceGroupName --name $virtualMachine.name --size $virtualMachine.size --os-disk-caching $virtualMachine.osDisk.caching --os-disk-size-gb $virtualMachine.osDisk.sizeGB --subnet $virtualMachine.subnetId --image $virtualMachine.imageId --admin-username $virtualMachine.adminLogin.username --admin-password $virtualMachine.adminLogin.password --public-ip-address '""' --nsg '""' --security-type $virtualMachine.securityType --priority $virtualMachine.priorityMode --eviction-policy $virtualMachine.evictionPolicy --enable-hibernation $virtualMachine.hibernation.enable
}

######################
# Artist Workstation #
######################

$regionName        = "WestUS2"
$nameSuffix        = "West"
$resourceGroupName = "AAA"
$virtualNetwork = @{
  subscriptionId    = az account show --query id --output tsv
  resourceGroupName = "ArtistAnywhere.Network.$nameSuffix"
  name              = "Studio-$nameSuffix"
  subnetName        = "Workstation"
}
$virtualMachine = @{
  name     = "LnxArtistN"
  size     = "Standard_NV36ads_A10_v5"
  imageId  = "AlmaLinux:AlmaLinux-x86_64:8-Gen2:Latest"
  subnetId = "/subscriptions/$($virtualNetwork.subscriptionId)/resourceGroups/$($virtualNetwork.resourceGroupName)/providers/Microsoft.Network/virtualNetworks/$($virtualNetwork.name)/subnets/$($virtualNetwork.subnetName)"
  adminLogin = @{
    username = "xadmin"
    password = "P@ssword1234"
  }
  osDisk = @{
    ephemeral = @{
      enable    = $false
      placement = "ResourceDisk"
    }
    caching = "ReadWrite"
    sizeGB  = 512
  }
  securityType = "Standard"
  hibernation = @{
    enable = $false
  }
}
az group create --name $resourceGroupName --location $regionName
if ($virtualMachine.osDisk.ephemeral.enable) {
  az vm create --resource-group $resourceGroupName --name $virtualMachine.name --size $virtualMachine.size --ephemeral-os-disk $virtualMachine.osDisk.ephemeral.enable --ephemeral-os-disk-placement $virtualMachine.osDisk.ephemeral.placement --os-disk-caching $virtualMachine.osDisk.caching --os-disk-size-gb $virtualMachine.osDisk.sizeGB --subnet $virtualMachine.subnetId --image $virtualMachine.imageId --admin-username $virtualMachine.adminLogin.username --admin-password $virtualMachine.adminLogin.password --public-ip-address '""' --nsg '""' --security-type $virtualMachine.securityType --enable-hibernation $virtualMachine.hibernation.enable
} else {
  az vm create --resource-group $resourceGroupName --name $virtualMachine.name --size $virtualMachine.size --os-disk-caching $virtualMachine.osDisk.caching --os-disk-size-gb $virtualMachine.osDisk.sizeGB --subnet $virtualMachine.subnetId --image $virtualMachine.imageId --admin-username $virtualMachine.adminLogin.username --admin-password $virtualMachine.adminLogin.password --public-ip-address '""' --nsg '""' --security-type $virtualMachine.securityType --enable-hibernation $virtualMachine.hibernation.enable
}

$regionName        = "WestUS2"
$nameSuffix        = "West"
$resourceGroupName = "AAA"
$virtualNetwork = @{
  subscriptionId    = az account show --query id --output tsv
  resourceGroupName = "ArtistAnywhere.Network.$nameSuffix"
  name              = "Studio-$nameSuffix"
  subnetName        = "Workstation"
}
$virtualMachine = @{
  name     = "LnxArtistA"
  size     = "Standard_NG32ads_V620_v1"
  imageId  = "AlmaLinux:AlmaLinux-x86_64:8-Gen2:Latest"
  subnetId = "/subscriptions/$($virtualNetwork.subscriptionId)/resourceGroups/$($virtualNetwork.resourceGroupName)/providers/Microsoft.Network/virtualNetworks/$($virtualNetwork.name)/subnets/$($virtualNetwork.subnetName)"
  adminLogin = @{
    username = "xadmin"
    password = "P@ssword1234"
  }
  osDisk = @{
    ephemeral = @{
      enable    = $false
      placement = "ResourceDisk"
    }
    caching = "ReadWrite"
    sizeGB  = 512
  }
  securityType = "Standard"
  hibernation = @{
    enable = $false
  }
}
az group create --name $resourceGroupName --location $regionName
if ($virtualMachine.osDisk.ephemeral.enable) {
  az vm create --resource-group $resourceGroupName --name $virtualMachine.name --size $virtualMachine.size --ephemeral-os-disk $virtualMachine.osDisk.ephemeral.enable --ephemeral-os-disk-placement $virtualMachine.osDisk.ephemeral.placement --os-disk-caching $virtualMachine.osDisk.caching --os-disk-size-gb $virtualMachine.osDisk.sizeGB --subnet $virtualMachine.subnetId --image $virtualMachine.imageId --admin-username $virtualMachine.adminLogin.username --admin-password $virtualMachine.adminLogin.password --public-ip-address '""' --nsg '""' --security-type $virtualMachine.securityType --enable-hibernation $virtualMachine.hibernation.enable
} else {
  az vm create --resource-group $resourceGroupName --name $virtualMachine.name --size $virtualMachine.size --os-disk-caching $virtualMachine.osDisk.caching --os-disk-size-gb $virtualMachine.osDisk.sizeGB --subnet $virtualMachine.subnetId --image $virtualMachine.imageId --admin-username $virtualMachine.adminLogin.username --admin-password $virtualMachine.adminLogin.password --public-ip-address '""' --nsg '""' --security-type $virtualMachine.securityType --enable-hibernation $virtualMachine.hibernation.enable
}
