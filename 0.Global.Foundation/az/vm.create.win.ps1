#################
# Job Scheduler #
#################

$regionName        = "WestUS2"
$resourceGroupName = "AAA"
$virtualNetwork = @{
  subscriptionId    = az account show --query id --output tsv
  resourceGroupName = "ArtistAnywhere.Network"
  name              = "Studio"
  subnetName        = "Farm"
}
$virtualMachine = @{
  name     = "WinScheduler"
  size     = "Standard_D8as_v5"
  imageId  = "MicrosoftWindowsServer:WindowsServer:2022-Datacenter-G2:Latest"
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
$resourceGroupName = "AAA"
$virtualNetwork = @{
  subscriptionId    = az account show --query id --output tsv
  resourceGroupName = "ArtistAnywhere.Network"
  name              = "Studio"
  subnetName        = "Farm"
}
$virtualMachine = @{
  name     = "WinFarmC"
  size     = "Standard_HB120rs_v3"
  imageId  = "MicrosoftWindowsDesktop:Windows-10:Win10-22H2-Pro-G2:Latest"
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
$resourceGroupName = "AAA"
$virtualNetwork = @{
  subscriptionId    = az account show --query id --output tsv
  resourceGroupName = "ArtistAnywhere.Network"
  name              = "Studio"
  subnetName        = "Farm"
}
$virtualMachine = @{
  name     = "WinFarmG"
  size     = "Standard_NV36ads_A10_v5"
  imageId  = "MicrosoftWindowsDesktop:Windows-10:Win10-22H2-Pro-G2:Latest"
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
    sizeGB  = 512
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
$resourceGroupName = "AAA"
$virtualNetwork = @{
  subscriptionId    = az account show --query id --output tsv
  resourceGroupName = "ArtistAnywhere.Network"
  name              = "Studio"
  subnetName        = "Workstation"
}
$virtualMachine = @{
  name     = "WinArtistN"
  size     = "Standard_NV36ads_A10_v5"
  imageId  = "MicrosoftWindowsDesktop:Windows-11:Win11-23H2-Pro:Latest"
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
$resourceGroupName = "AAA"
$virtualNetwork = @{
  subscriptionId    = az account show --query id --output tsv
  resourceGroupName = "ArtistAnywhere.Network"
  name              = "Studio"
  subnetName        = "Workstation"
}
$virtualMachine = @{
  name     = "WinArtistA"
  size     = "Standard_NG32ads_V620_v1"
  imageId  = "MicrosoftWindowsDesktop:Windows-11:Win11-23H2-Pro:Latest"
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
