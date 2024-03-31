###########
# Storage #
###########

$resourceGroupName = "AAA"
$resourceLocation = @{
  region   = "WestUS"
  edgeZone = "LosAngeles"
}
$virtualNetwork = @{
  subscriptionId    = az account show --query id --output tsv
  resourceGroupName = "ArtistAnywhere.Network.West"
  name              = "Studio-West"
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
    caching = "None"
  }
  dataDisk = @{
    count   = 1
    sizeGB  = 512
    caching = "ReadWrite"
    type    = "Premium_LRS"
  }
}
az group create --name $resourceGroupName --location $resourceLocation.region
az vm create --resource-group $resourceGroupName --name $virtualMachine.name --size $virtualMachine.size --os-disk-size-gb $virtualMachine.osDisk.sizeGB --os-disk-caching $virtualMachine.osDisk.caching --image $virtualMachine.imageId --admin-username $virtualMachine.adminLogin.username --admin-password $virtualMachine.adminLogin.password --subnet "/subscriptions/$($virtualNetwork.subscriptionId)/resourceGroups/$($virtualNetwork.resourceGroupName)/providers/Microsoft.Network/virtualNetworks/$($virtualNetwork.name)/subnets/$($virtualNetwork.subnetName)" --public-ip-address '""' --nsg '""'
for ($i = 1; $i -le $virtualMachine.dataDisk.count; $i++) {
  $dataDiskName = $virtualMachine.name + "_DataDisk_$i"
  az vm disk attach --resource-group $resourceGroupName --name $dataDiskName --sku $virtualMachine.dataDisk.type --size-gb $virtualMachine.dataDisk.sizeGB --caching $virtualMachine.dataDisk.caching --vm-name $virtualMachine.name --new
}

#################
# Job Scheduler #
#################

$resourceGroupName = "AAA"
$resourceLocation = @{
  region   = "WestUS"
  edgeZone = "LosAngeles"
}
$virtualNetwork = @{
  subscriptionId    = az account show --query id --output tsv
  resourceGroupName = "ArtistAnywhere.Network.West.Edge"
  name              = "Studio-West-Edge"
  subnetName        = "Farm"
}
$virtualMachine = @{
  name    = "LnxScheduler"
  size    = "Standard_E8s_v4"
  imageId = "RESF:RockyLinux-x86_64:8-Base:Latest"
  adminLogin = @{
    username = "xadmin"
    password = "P@ssword1234"
  }
  osDisk = @{
    sizeGB  = 0
    caching = "ReadWrite"
  }
}
az group create --name $resourceGroupName --location $resourceLocation.region
az vm create --resource-group $resourceGroupName --edge-zone $resourceLocation.edgeZone --name $virtualMachine.name --size $virtualMachine.size --os-disk-size-gb $virtualMachine.osDisk.sizeGB --os-disk-caching $virtualMachine.osDisk.caching --image $virtualMachine.imageId --admin-username $virtualMachine.adminLogin.username --admin-password $virtualMachine.adminLogin.password --subnet "/subscriptions/$($virtualNetwork.subscriptionId)/resourceGroups/$($virtualNetwork.resourceGroupName)/providers/Microsoft.Network/virtualNetworks/$($virtualNetwork.name)/subnets/$($virtualNetwork.subnetName)" --public-ip-address '""' --nsg '""'

###############
# Render Farm #
###############

$resourceGroupName = "AAA"
$resourceLocation = @{
  region   = "WestUS"
  edgeZone = "LosAngeles"
}
$virtualNetwork = @{
  subscriptionId    = az account show --query id --output tsv
  resourceGroupName = "ArtistAnywhere.Network.West.Edge"
  name              = "Studio-West-Edge"
  subnetName        = "Farm"
}
$virtualMachine = @{
  name    = "LnxFarmC"
  size    = "Standard_HB120rs_v3"
  imageId = "RESF:RockyLinux-x86_64:8-Base:Latest"
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
az group create --name $resourceGroupName --location $resourceLocation.region
if ($virtualMachine.osDisk.ephemeral.enable) {
  az vm create --resource-group $resourceGroupName --edge-zone $resourceLocation.edgeZone --name $virtualMachine.name --size $virtualMachine.size --os-disk-size-gb $virtualMachine.osDisk.sizeGB --os-disk-caching $virtualMachine.osDisk.caching --ephemeral-os-disk $virtualMachine.osDisk.ephemeral.enable --ephemeral-os-disk-placement $virtualMachine.osDisk.ephemeral.placement --image $virtualMachine.imageId --admin-username $virtualMachine.adminLogin.username --admin-password $virtualMachine.adminLogin.password --subnet "/subscriptions/$($virtualNetwork.subscriptionId)/resourceGroups/$($virtualNetwork.resourceGroupName)/providers/Microsoft.Network/virtualNetworks/$($virtualNetwork.name)/subnets/$($virtualNetwork.subnetName)" --public-ip-address '""' --nsg '""' --priority $virtualMachine.priorityMode --eviction-policy $virtualMachine.evictionPolicy
} else {
  az vm create --resource-group $resourceGroupName --edge-zone $resourceLocation.edgeZone --name $virtualMachine.name --size $virtualMachine.size --os-disk-size-gb $virtualMachine.osDisk.sizeGB --os-disk-caching $virtualMachine.osDisk.caching --image $virtualMachine.imageId --admin-username $virtualMachine.adminLogin.username --admin-password $virtualMachine.adminLogin.password --subnet "/subscriptions/$($virtualNetwork.subscriptionId)/resourceGroups/$($virtualNetwork.resourceGroupName)/providers/Microsoft.Network/virtualNetworks/$($virtualNetwork.name)/subnets/$($virtualNetwork.subnetName)" --public-ip-address '""' --nsg '""' --priority $virtualMachine.priorityMode --eviction-policy $virtualMachine.evictionPolicy
}

$resourceGroupName = "AAA"
$resourceLocation = @{
  region   = "WestUS"
  edgeZone = "LosAngeles"
}
$virtualNetwork = @{
  subscriptionId    = az account show --query id --output tsv
  resourceGroupName = "ArtistAnywhere.Network.West.Edge"
  name              = "Studio-West-Edge"
  subnetName        = "Farm"
}
$virtualMachine = @{
  name    = "LnxFarmG"
  size    = "Standard_NV36ads_A10_v5"
  imageId = "RESF:RockyLinux-x86_64:8-Base:Latest"
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
az group create --name $resourceGroupName --location $resourceLocation.region
if ($virtualMachine.osDisk.ephemeral.enable) {
  az vm create --resource-group $resourceGroupName --edge-zone $resourceLocation.edgeZone --name $virtualMachine.name --size $virtualMachine.size --os-disk-size-gb $virtualMachine.osDisk.sizeGB --os-disk-caching $virtualMachine.osDisk.caching --ephemeral-os-disk $virtualMachine.osDisk.ephemeral.enable --ephemeral-os-disk-placement $virtualMachine.osDisk.ephemeral.placement --image $virtualMachine.imageId --admin-username $virtualMachine.adminLogin.username --admin-password $virtualMachine.adminLogin.password --subnet "/subscriptions/$($virtualNetwork.subscriptionId)/resourceGroups/$($virtualNetwork.resourceGroupName)/providers/Microsoft.Network/virtualNetworks/$($virtualNetwork.name)/subnets/$($virtualNetwork.subnetName)" --public-ip-address '""' --nsg '""' --priority $virtualMachine.priorityMode --eviction-policy $virtualMachine.evictionPolicy
} else {
  az vm create --resource-group $resourceGroupName --edge-zone $resourceLocation.edgeZone --name $virtualMachine.name --size $virtualMachine.size --os-disk-size-gb $virtualMachine.osDisk.sizeGB --os-disk-caching $virtualMachine.osDisk.caching --image $virtualMachine.imageId --admin-username $virtualMachine.adminLogin.username --admin-password $virtualMachine.adminLogin.password --subnet "/subscriptions/$($virtualNetwork.subscriptionId)/resourceGroups/$($virtualNetwork.resourceGroupName)/providers/Microsoft.Network/virtualNetworks/$($virtualNetwork.name)/subnets/$($virtualNetwork.subnetName)" --public-ip-address '""' --nsg '""' --priority $virtualMachine.priorityMode --eviction-policy $virtualMachine.evictionPolicy
}

######################
# Artist Workstation #
######################

$resourceGroupName = "AAA"
$resourceLocation = @{
  region   = "WestUS"
  edgeZone = "LosAngeles"
}
$virtualNetwork = @{
  subscriptionId    = az account show --query id --output tsv
  resourceGroupName = "ArtistAnywhere.Network.West.Edge"
  name              = "Studio-West-Edge"
  subnetName        = "Workstation"
}
$virtualMachine = @{
  name    = "LnxArtistN"
  size    = "Standard_NV36ads_A10_v5"
  imageId = "RESF:RockyLinux-x86_64:8-Base:Latest"
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
az group create --name $resourceGroupName --location $resourceLocation.region
az vm create --resource-group $resourceGroupName --edge-zone $resourceLocation.edgeZone --name $virtualMachine.name --size $virtualMachine.size --os-disk-size-gb $virtualMachine.osDisk.sizeGB --os-disk-caching $virtualMachine.osDisk.caching --image $virtualMachine.imageId --admin-username $virtualMachine.adminLogin.username --admin-password $virtualMachine.adminLogin.password --subnet "/subscriptions/$($virtualNetwork.subscriptionId)/resourceGroups/$($virtualNetwork.resourceGroupName)/providers/Microsoft.Network/virtualNetworks/$($virtualNetwork.name)/subnets/$($virtualNetwork.subnetName)" --public-ip-address '""' --nsg '""'

$resourceGroupName = "AAA"
$resourceLocation = @{
  region   = "WestUS"
  edgeZone = "LosAngeles"
}
$virtualNetwork = @{
  subscriptionId    = az account show --query id --output tsv
  resourceGroupName = "ArtistAnywhere.Network.West.Edge"
  name              = "Studio-West-Edge"
  subnetName        = "Workstation"
}
$virtualMachine = @{
  name    = "LnxArtistA"
  size    = "Standard_NG32ads_V620_v1"
  imageId = "RESF:RockyLinux-x86_64:8-Base:Latest"
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
az group create --name $resourceGroupName --location $resourceLocation.region
az vm create --resource-group $resourceGroupName --edge-zone $resourceLocation.edgeZone --name $virtualMachine.name --size $virtualMachine.size --os-disk-size-gb $virtualMachine.osDisk.sizeGB --os-disk-caching $virtualMachine.osDisk.caching --image $virtualMachine.imageId --admin-username $virtualMachine.adminLogin.username --admin-password $virtualMachine.adminLogin.password --subnet "/subscriptions/$($virtualNetwork.subscriptionId)/resourceGroups/$($virtualNetwork.resourceGroupName)/providers/Microsoft.Network/virtualNetworks/$($virtualNetwork.name)/subnets/$($virtualNetwork.subnetName)" --public-ip-address '""' --nsg '""'