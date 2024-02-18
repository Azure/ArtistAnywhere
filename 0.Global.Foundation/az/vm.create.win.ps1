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
  name    = "WinScheduler"
  size    = "Standard_D8as_v5"
  imageId = "MicrosoftWindowsServer:WindowsServer:2022-Datacenter-G2:Latest"
  adminLogin = @{
    username = "xadmin"
    password = "P@ssword1234"
  }
  osDisk = @{
    sizeGB  = 0
    caching = "ReadWrite"
  }
}
az group create --name $resourceGroupName --location $regionName
az vm create --resource-group $resourceGroupName --name $virtualMachine.name --size $virtualMachine.size --os-disk-size-gb $virtualMachine.osDisk.sizeGB --os-disk-caching $virtualMachine.osDisk.caching --image $virtualMachine.imageId --admin-username $virtualMachine.adminLogin.username --admin-password $virtualMachine.adminLogin.password --subnet "/subscriptions/$($virtualNetwork.subscriptionId)/resourceGroups/$($virtualNetwork.resourceGroupName)/providers/Microsoft.Network/virtualNetworks/$($virtualNetwork.name)/subnets/$($virtualNetwork.subnetName)" --public-ip-address '""' --nsg '""'

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
  name    = "WinFarmC"
  size    = "Standard_HB120rs_v3"
  imageId = "MicrosoftWindowsDesktop:Windows-10:Win10-22H2-Pro-G2:Latest"
  adminLogin = @{
    username = "xadmin"
    password = "P@ssword1234"
  }
  osDisk = @{
    sizeGB  = 360
    caching = "ReadOnly"
    ephemeral = @{
      enable    = $true
      placement = "ResourceDisk"
    }
  }
  priorityMode   = "Spot"
  evictionPolicy = "Delete"
}
az group create --name $resourceGroupName --location $regionName
if ($virtualMachine.osDisk.ephemeral.enable) {
  az vm create --resource-group $resourceGroupName --name $virtualMachine.name --size $virtualMachine.size --os-disk-size-gb $virtualMachine.osDisk.sizeGB --os-disk-caching $virtualMachine.osDisk.caching --ephemeral-os-disk $virtualMachine.osDisk.ephemeral.enable --ephemeral-os-disk-placement $virtualMachine.osDisk.ephemeral.placement --image $virtualMachine.imageId --admin-username $virtualMachine.adminLogin.username --admin-password $virtualMachine.adminLogin.password --subnet "/subscriptions/$($virtualNetwork.subscriptionId)/resourceGroups/$($virtualNetwork.resourceGroupName)/providers/Microsoft.Network/virtualNetworks/$($virtualNetwork.name)/subnets/$($virtualNetwork.subnetName)" --public-ip-address '""' --nsg '""' --priority $virtualMachine.priorityMode --eviction-policy $virtualMachine.evictionPolicy
} else {
  az vm create --resource-group $resourceGroupName --name $virtualMachine.name --size $virtualMachine.size --os-disk-size-gb $virtualMachine.osDisk.sizeGB --os-disk-caching $virtualMachine.osDisk.caching --image $virtualMachine.imageId --admin-username $virtualMachine.adminLogin.username --admin-password $virtualMachine.adminLogin.password --subnet "/subscriptions/$($virtualNetwork.subscriptionId)/resourceGroups/$($virtualNetwork.resourceGroupName)/providers/Microsoft.Network/virtualNetworks/$($virtualNetwork.name)/subnets/$($virtualNetwork.subnetName)" --public-ip-address '""' --nsg '""' --priority $virtualMachine.priorityMode --eviction-policy $virtualMachine.evictionPolicy
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
  name    = "WinFarmG"
  size    = "Standard_NV36ads_A10_v5"
  imageId = "MicrosoftWindowsDesktop:Windows-10:Win10-22H2-Pro-G2:Latest"
  adminLogin = @{
    username = "xadmin"
    password = "P@ssword1234"
  }
  osDisk = @{
    sizeGB  = 512
    caching = "ReadOnly"
    ephemeral = @{
      enable    = $true
      placement = "ResourceDisk"
    }
  }
  priorityMode   = "Spot"
  evictionPolicy = "Delete"
}
az group create --name $resourceGroupName --location $regionName
if ($virtualMachine.osDisk.ephemeral.enable) {
  az vm create --resource-group $resourceGroupName --name $virtualMachine.name --size $virtualMachine.size --os-disk-size-gb $virtualMachine.osDisk.sizeGB --os-disk-caching $virtualMachine.osDisk.caching --ephemeral-os-disk $virtualMachine.osDisk.ephemeral.enable --ephemeral-os-disk-placement $virtualMachine.osDisk.ephemeral.placement --image $virtualMachine.imageId --admin-username $virtualMachine.adminLogin.username --admin-password $virtualMachine.adminLogin.password --subnet "/subscriptions/$($virtualNetwork.subscriptionId)/resourceGroups/$($virtualNetwork.resourceGroupName)/providers/Microsoft.Network/virtualNetworks/$($virtualNetwork.name)/subnets/$($virtualNetwork.subnetName)" --public-ip-address '""' --nsg '""' --priority $virtualMachine.priorityMode --eviction-policy $virtualMachine.evictionPolicy
} else {
  az vm create --resource-group $resourceGroupName --name $virtualMachine.name --size $virtualMachine.size --os-disk-size-gb $virtualMachine.osDisk.sizeGB --os-disk-caching $virtualMachine.osDisk.caching --image $virtualMachine.imageId --admin-username $virtualMachine.adminLogin.username --admin-password $virtualMachine.adminLogin.password --subnet "/subscriptions/$($virtualNetwork.subscriptionId)/resourceGroups/$($virtualNetwork.resourceGroupName)/providers/Microsoft.Network/virtualNetworks/$($virtualNetwork.name)/subnets/$($virtualNetwork.subnetName)" --public-ip-address '""' --nsg '""' --priority $virtualMachine.priorityMode --eviction-policy $virtualMachine.evictionPolicy
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
  name    = "WinArtistN"
  size    = "Standard_NV36ads_A10_v5"
  imageId = "MicrosoftWindowsDesktop:Windows-11:Win11-23H2-Pro:Latest"
  adminLogin = @{
    username = "xadmin"
    password = "P@ssword1234"
  }
  osDisk = @{
    sizeGB  = 512
    caching = "ReadWrite"
  }
  hibernation = @{
    enable = $false
  }
}
az group create --name $resourceGroupName --location $regionName
az vm create --resource-group $resourceGroupName --name $virtualMachine.name --size $virtualMachine.size --os-disk-size-gb $virtualMachine.osDisk.sizeGB --os-disk-caching $virtualMachine.osDisk.caching --image $virtualMachine.imageId --admin-username $virtualMachine.adminLogin.username --admin-password $virtualMachine.adminLogin.password --subnet "/subscriptions/$($virtualNetwork.subscriptionId)/resourceGroups/$($virtualNetwork.resourceGroupName)/providers/Microsoft.Network/virtualNetworks/$($virtualNetwork.name)/subnets/$($virtualNetwork.subnetName)" --public-ip-address '""' --nsg '""'

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
  name    = "WinArtistA"
  size    = "Standard_NG32ads_V620_v1"
  imageId = "MicrosoftWindowsDesktop:Windows-11:Win11-23H2-Pro:Latest"
  adminLogin = @{
    username = "xadmin"
    password = "P@ssword1234"
  }
  osDisk = @{
    sizeGB  = 512
    caching = "ReadWrite"
  }
  hibernation = @{
    enable = $false
  }
}
az group create --name $resourceGroupName --location $regionName
az vm create --resource-group $resourceGroupName --name $virtualMachine.name --size $virtualMachine.size --os-disk-size-gb $virtualMachine.osDisk.sizeGB --os-disk-caching $virtualMachine.osDisk.caching --image $virtualMachine.imageId --admin-username $virtualMachine.adminLogin.username --admin-password $virtualMachine.adminLogin.password --subnet "/subscriptions/$($virtualNetwork.subscriptionId)/resourceGroups/$($virtualNetwork.resourceGroupName)/providers/Microsoft.Network/virtualNetworks/$($virtualNetwork.name)/subnets/$($virtualNetwork.subnetName)" --public-ip-address '""' --nsg '""'
