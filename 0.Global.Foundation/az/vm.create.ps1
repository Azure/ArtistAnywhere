###########
# Storage #
###########

$resourceGroupName = "AAA"
$resourceLocation = @{
  region   = "WestUS2"
  edgeZone = ""
}
$virtualNetwork = @{
  subscriptionId    = az account show --query id --output tsv
  resourceGroupName = "ArtistAnywhere.Network.$($resourceLocation.region)"
  name              = "Studio"
  subnetName        = "Storage"
}
$virtualMachine = @{
  name    = "LnxStorage"
  size    = "Standard_L8s_v3"
  imageId = "RESF:RockyLinux-x86_64:8-Base:Latest"
  adminLogin = @{
    username = "xadmin"
    password = "P@ssword1234"
  }
  osDisk = @{
    sizeGB  = 0
    caching = "ReadOnly"
  }
  dataDisk = @{
    count   = 1
    sizeGB  = 512
    caching = "None"
    type    = "Standard_LRS"
  }
}
$subnetId = "/subscriptions/$($virtualNetwork.subscriptionId)/resourceGroups/$($virtualNetwork.resourceGroupName)/providers/Microsoft.Network/virtualNetworks/$($virtualNetwork.name)/subnets/$($virtualNetwork.subnetName)"
az group create --name $resourceGroupName --location $resourceLocation.region
az vm create --resource-group $resourceGroupName --name $virtualMachine.name --size $virtualMachine.size --os-disk-size-gb $virtualMachine.osDisk.sizeGB --os-disk-caching $virtualMachine.osDisk.caching --image $virtualMachine.imageId --admin-username $virtualMachine.adminLogin.username --admin-password $virtualMachine.adminLogin.password --subnet $subnetId --public-ip-address '""' --nsg '""'
for ($i = 1; $i -le $virtualMachine.dataDisk.count; $i++) {
  $dataDiskName = $virtualMachine.name + "_DataDisk_$i"
  az vm disk attach --resource-group $resourceGroupName --name $dataDiskName --sku $virtualMachine.dataDisk.type --size-gb $virtualMachine.dataDisk.sizeGB --caching $virtualMachine.dataDisk.caching --vm-name $virtualMachine.name --new
}

#################
# Job Scheduler #
#################

$osTypeWindows     = $false
$extendedLocation  = $false
$resourceGroupName = "AAA"
$resourceLocation = @{
  region   = if ($extendedLocation) {"WestUS"} else {"WestUS2"}
  edgeZone = "LosAngeles"
}
$virtualNetwork = @{
  subscriptionId    = az account show --query id --output tsv
  resourceGroupName = "ArtistAnywhere.Network.$($resourceLocation.region)$(if ($extendedLocation) {".$($resourceLocation.edgeZone)"})"
  name              = "Studio"
  subnetName        = "Farm"
}
$virtualMachine = @{
  name    = if ($osTypeWindows) {"WinScheduler"} else {"LnxScheduler"}
  size    = "Standard_E8s_v4"
  imageId = if ($osTypeWindows) {"MicrosoftWindowsServer:WindowsServer:2022-Datacenter-Azure-Edition:Latest"} else {"RESF:RockyLinux-x86_64:8-Base:Latest"}
  adminLogin = @{
    username = "xadmin"
    password = "P@ssword1234"
  }
  osDisk = @{
    sizeGB  = 0
    caching = "ReadOnly"
  }
}
az group create --name $resourceGroupName --location $resourceLocation.region
$edgeZone = if ($extendedLocation) {" --edge-zone $($resourceLocation.edgeZone)"} else {""}
$subnetId = "/subscriptions/$($virtualNetwork.subscriptionId)/resourceGroups/$($virtualNetwork.resourceGroupName)/providers/Microsoft.Network/virtualNetworks/$($virtualNetwork.name)/subnets/$($virtualNetwork.subnetName)"
$vmCreate = "az vm create --resource-group $resourceGroupName$edgeZone --name $($virtualMachine.name) --size $($virtualMachine.size) --os-disk-size-gb $($virtualMachine.osDisk.sizeGB) --os-disk-caching $($virtualMachine.osDisk.caching) --image $($virtualMachine.imageId) --admin-username $($virtualMachine.adminLogin.username) --admin-password $($virtualMachine.adminLogin.password) --subnet $subnetId --public-ip-address '""""' --nsg '""""'"
Invoke-Expression -Command $vmCreate

###############
# Render Farm #
###############

$osTypeWindows     = $false
$extendedLocation  = $false
$resourceGroupName = "AAA"
$resourceLocation = @{
  region   = if ($extendedLocation) {"WestUS"} else {"WestUS2"}
  edgeZone = "LosAngeles"
}
$virtualNetwork = @{
  subscriptionId    = az account show --query id --output tsv
  resourceGroupName = "ArtistAnywhere.Network.$($resourceLocation.region)$(if ($extendedLocation) {".$($resourceLocation.edgeZone)"})"
  name              = "Studio"
  subnetName        = "Farm"
}
$virtualMachine = @{
  name    = if ($osTypeWindows) {"WinFarmC"} else {"LnxFarmC"}
  size    = "Standard_HB120rs_v2"
  imageId = if ($osTypeWindows) {"MicrosoftWindowsDesktop:Windows-10:Win10-22H2-Ent-G2:Latest"} else {"RESF:RockyLinux-x86_64:8-Base:Latest"}
  adminLogin = @{
    username = "xadmin"
    password = "P@ssword1234"
  }
  osDisk = @{
    sizeGB  = 480
    caching = "ReadOnly"
    ephemeral = @{
      enable    = $true
      placement = "ResourceDisk"
    }
  }
  spot = @{
    enable         = $true
    evictionPolicy = "Delete"
  }
}
az group create --name $resourceGroupName --location $resourceLocation.region
$edgeZone = if ($extendedLocation) {" --edge-zone $($resourceLocation.edgeZone)"} else {""}
$priority = if ($virtualMachine.spot.enable) {"Spot"} else {"Regular"}
$subnetId = "/subscriptions/$($virtualNetwork.subscriptionId)/resourceGroups/$($virtualNetwork.resourceGroupName)/providers/Microsoft.Network/virtualNetworks/$($virtualNetwork.name)/subnets/$($virtualNetwork.subnetName)"
$vmCreate = "az vm create --resource-group $resourceGroupName$edgeZone --name $($virtualMachine.name) --size $($virtualMachine.size) --os-disk-size-gb $($virtualMachine.osDisk.sizeGB) --os-disk-caching $($virtualMachine.osDisk.caching) --image $($virtualMachine.imageId) --admin-username $($virtualMachine.adminLogin.username) --admin-password $($virtualMachine.adminLogin.password) --subnet $subnetId --public-ip-address '""""' --nsg '""""' --priority $priority"
$vmCreate = if ($virtualMachine.osDisk.ephemeral.enable) {"$vmCreate --ephemeral-os-disk $($virtualMachine.osDisk.ephemeral.enable) --ephemeral-os-disk-placement $($virtualMachine.osDisk.ephemeral.placement)"} else {$vmCreate}
$vmCreate = if ($virtualMachine.spot.enable) {"$vmCreate --eviction-policy $($virtualMachine.spot.evictionPolicy)"} else {$vmCreate}
Invoke-Expression -Command $vmCreate

$osTypeWindows     = $false
$extendedLocation  = $false
$resourceGroupName = "AAA"
$resourceLocation = @{
  region   = if ($extendedLocation) {"WestUS"} else {"WestUS2"}
  edgeZone = "LosAngeles"
}
$virtualNetwork = @{
  subscriptionId    = az account show --query id --output tsv
  resourceGroupName = "ArtistAnywhere.Network.$($resourceLocation.region)"
  name              = "Studio"
  subnetName        = "Farm"
}
$virtualMachine = @{
  name    = if ($osTypeWindows) {"WinFarmG"} else {"LnxFarmG"}
  size    = "Standard_NV36ads_A10_v5"
  imageId = if ($osTypeWindows) {"MicrosoftWindowsDesktop:Windows-10:Win10-22H2-Ent-G2:Latest"} else {"RESF:RockyLinux-x86_64:8-Base:Latest"}
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
  spot = @{
    enable         = $true
    evictionPolicy = "Delete"
  }
}
az group create --name $resourceGroupName --location $resourceLocation.region
$edgeZone = if ($extendedLocation) {" --edge-zone $($resourceLocation.edgeZone)"} else {""}
$priority = if ($virtualMachine.spot.enable) {"Spot"} else {"Regular"}
$subnetId = "/subscriptions/$($virtualNetwork.subscriptionId)/resourceGroups/$($virtualNetwork.resourceGroupName)/providers/Microsoft.Network/virtualNetworks/$($virtualNetwork.name)/subnets/$($virtualNetwork.subnetName)"
$vmCreate = "az vm create --resource-group $resourceGroupName$edgeZone --name $($virtualMachine.name) --size $($virtualMachine.size) --os-disk-size-gb $($virtualMachine.osDisk.sizeGB) --os-disk-caching $($virtualMachine.osDisk.caching) --image $($virtualMachine.imageId) --admin-username $($virtualMachine.adminLogin.username) --admin-password $($virtualMachine.adminLogin.password) --subnet $subnetId --public-ip-address '""""' --nsg '""""' --priority $priority"
$vmCreate = if ($virtualMachine.osDisk.ephemeral.enable) {"$vmCreate --ephemeral-os-disk $($virtualMachine.osDisk.ephemeral.enable) --ephemeral-os-disk-placement $($virtualMachine.osDisk.ephemeral.placement)"} else {$vmCreate}
$vmCreate = if ($virtualMachine.spot.enable) {"$vmCreate --eviction-policy $($virtualMachine.spot.evictionPolicy)"} else {$vmCreate}
Invoke-Expression -Command $vmCreate

######################
# Artist Workstation #
######################

$osTypeWindows     = $false
$extendedLocation  = $false
$resourceGroupName = "AAA"
$resourceLocation = @{
  region   = if ($extendedLocation) {"WestUS"} else {"WestUS2"}
  edgeZone = "LosAngeles"
}
$virtualNetwork = @{
  subscriptionId    = az account show --query id --output tsv
  resourceGroupName = "ArtistAnywhere.Network.$($resourceLocation.region)$(if ($extendedLocation) {".$($resourceLocation.edgeZone)"})"
  name              = "Studio"
  subnetName        = "Workstation"
}
$virtualMachine = @{
  name    = if ($osTypeWindows) {"WinArtistN"} else {"LnxArtistN"}
  size    = "Standard_NV36ads_A10_v5"
  imageId = if ($osTypeWindows) {"MicrosoftWindowsDesktop:Windows-11:Win11-23H2-Ent:Latest"} else {"RESF:RockyLinux-x86_64:8-Base:Latest"}
  adminLogin = @{
    username = "xadmin"
    password = "P@ssword1234"
  }
  osDisk = @{
    sizeGB  = 512
    caching = "ReadOnly"
  }
  hibernation = @{
    enable = $false
  }
}
az group create --name $resourceGroupName --location $resourceLocation.region
$edgeZone = if ($extendedLocation) {" --edge-zone $($resourceLocation.edgeZone)"} else {""}
$subnetId = "/subscriptions/$($virtualNetwork.subscriptionId)/resourceGroups/$($virtualNetwork.resourceGroupName)/providers/Microsoft.Network/virtualNetworks/$($virtualNetwork.name)/subnets/$($virtualNetwork.subnetName)"
$vmCreate = "az vm create --resource-group $resourceGroupName$edgeZone --name $($virtualMachine.name) --size $($virtualMachine.size) --os-disk-size-gb $($virtualMachine.osDisk.sizeGB) --os-disk-caching $($virtualMachine.osDisk.caching) --image $($virtualMachine.imageId) --admin-username $($virtualMachine.adminLogin.username) --admin-password $($virtualMachine.adminLogin.password) --subnet $subnetId --public-ip-address '""""' --nsg '""""'"
Invoke-Expression -Command $vmCreate

$osTypeWindows     = $false
$extendedLocation  = $false
$resourceGroupName = "AAA"
$resourceLocation = @{
  region   = if ($extendedLocation) {"WestUS"} else {"WestUS2"}
  edgeZone = "LosAngeles"
}
$virtualNetwork = @{
  subscriptionId    = az account show --query id --output tsv
  resourceGroupName = "ArtistAnywhere.Network.$($resourceLocation.region)"
  name              = "Studio"
  subnetName        = "Workstation"
}
$virtualMachine = @{
  name    = if ($osTypeWindows) {"WinArtistA"} else {"LnxArtistA"}
  size    = "Standard_NG32ads_V620_v1"
  imageId = if ($osTypeWindows) {"MicrosoftWindowsDesktop:Windows-11:Win11-23H2-Ent:Latest"} else {"RESF:RockyLinux-x86_64:8-Base:Latest"}
  adminLogin = @{
    username = "xadmin"
    password = "P@ssword1234"
  }
  osDisk = @{
    sizeGB  = 512
    caching = "ReadOnly"
  }
  hibernation = @{
    enable = $false
  }
}
az group create --name $resourceGroupName --location $resourceLocation.region
$edgeZone = if ($extendedLocation) {" --edge-zone $($resourceLocation.edgeZone)"} else {""}
$subnetId = "/subscriptions/$($virtualNetwork.subscriptionId)/resourceGroups/$($virtualNetwork.resourceGroupName)/providers/Microsoft.Network/virtualNetworks/$($virtualNetwork.name)/subnets/$($virtualNetwork.subnetName)"
$vmCreate = "az vm create --resource-group $resourceGroupName$edgeZone --name $($virtualMachine.name) --size $($virtualMachine.size) --os-disk-size-gb $($virtualMachine.osDisk.sizeGB) --os-disk-caching $($virtualMachine.osDisk.caching) --image $($virtualMachine.imageId) --admin-username $($virtualMachine.adminLogin.username) --admin-password $($virtualMachine.adminLogin.password) --subnet $subnetId --public-ip-address '""""' --nsg '""""'"
Invoke-Expression -Command $vmCreate
