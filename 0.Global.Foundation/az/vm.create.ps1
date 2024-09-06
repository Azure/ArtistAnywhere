###########
# Storage #
###########

$resourceGroupName = "AAA"
$resourceLocation = @{
  regionName       = "SouthCentralUS"
  extendedZoneName = ""
}
$virtualNetwork = @{
  subscriptionId    = az account show --query id --output tsv
  resourceGroupName = "ArtistAnywhere.Network.$($resourceLocation.regionName)"
  name              = "Studio"
  subnetName        = "Storage"
}
$virtualMachine = @{
  name    = "LnxStorage"
  size    = "Standard_L8s_v3"
  imageId = "RESF:RockyLinux-x86_64:9-Base:9.3.20231113"
  adminLogin = @{
    userName     = az keyvault secret show --vault-name "xstudio" --name "AdminUsername" --query value --output tsv
    sshKeyPublic = az keyvault secret show --vault-name "xstudio" --name "SSHKeyPublic" --query value
  }
  osDisk = @{
    sizeGB  = 256
    caching = "None"
  }
  dataDisk = @{
    count   = 1
    sizeGB  = 1024
    caching = "None"
    type    = "Standard_LRS"
  }
}
$subnetId = "/subscriptions/$($virtualNetwork.subscriptionId)/resourceGroups/$($virtualNetwork.resourceGroupName)/providers/Microsoft.Network/virtualNetworks/$($virtualNetwork.name)/subnets/$($virtualNetwork.subnetName)"
az group create --name $resourceGroupName --location $resourceLocation.regionName
az vm create --resource-group $resourceGroupName --name $virtualMachine.name --size $virtualMachine.size --os-disk-size-gb $virtualMachine.osDisk.sizeGB --os-disk-caching $virtualMachine.osDisk.caching --image $virtualMachine.imageId --admin-username $virtualMachine.adminLogin.userName --ssh-key-values $virtualMachine.adminLogin.sshKeyPublic --subnet $subnetId --public-ip-address '""' --nsg '""'
for ($i = 1; $i -le $virtualMachine.dataDisk.count; $i++) {
  $dataDiskName = $virtualMachine.name + "_DataDisk_$i"
  az vm disk attach --resource-group $resourceGroupName --name $dataDiskName --sku $virtualMachine.dataDisk.type --size-gb $virtualMachine.dataDisk.sizeGB --caching $virtualMachine.dataDisk.caching --vm-name $virtualMachine.name --new
}

###############
# Job Manager #
###############

$osTypeWindows     = $false
$extendedLocation  = $false
$resourceGroupName = "AAA"
$resourceLocation = @{
  regionName       = if ($extendedLocation) {"WestUS"} else {"SouthCentralUS"}
  extendedZoneName = "LosAngeles"
}
$virtualNetwork = @{
  subscriptionId    = az account show --query id --output tsv
  resourceGroupName = "ArtistAnywhere.Network.$($resourceLocation.regionName)$(if ($extendedLocation) {".$($resourceLocation.extendedZoneName)"})"
  name              = "Studio"
  subnetName        = "Farm"
}
$virtualMachine = @{
  name    = if ($osTypeWindows) {"WinJobManager"} else {"LnxJobManager"}
  size    = "Standard_E8s_v5"
  imageId = if ($osTypeWindows) {"MicrosoftWindowsServer:WindowsServer:2022-Datacenter-Azure-Edition:Latest"} else {"RESF:RockyLinux-x86_64:9-Base:9.3.20231113"}
  adminLogin = @{
    userName     = az keyvault secret show --vault-name "xstudio" --name "AdminUsername" --query value --output tsv
    userPassword = az keyvault secret show --vault-name "xstudio" --name "AdminPassword" --query value --output tsv
    sshKeyPublic = az keyvault secret show --vault-name "xstudio" --name "SSHKeyPublic" --query value
  }
  osDisk = @{
    sizeGB  = 256
    caching = "ReadOnly"
  }
}
az group create --name $resourceGroupName --location $resourceLocation.regionName
$extendedZone = if ($extendedLocation) {" --edge-zone $($resourceLocation.extendedZoneName)"} else {""}
$subnetId = "/subscriptions/$($virtualNetwork.subscriptionId)/resourceGroups/$($virtualNetwork.resourceGroupName)/providers/Microsoft.Network/virtualNetworks/$($virtualNetwork.name)/subnets/$($virtualNetwork.subnetName)"
$vmCreate = "az vm create --resource-group $resourceGroupName$extendedZone --name $($virtualMachine.name) --size $($virtualMachine.size) --os-disk-size-gb $($virtualMachine.osDisk.sizeGB) --os-disk-caching $($virtualMachine.osDisk.caching) --image $($virtualMachine.imageId) --admin-username $($virtualMachine.adminLogin.userName) --subnet $subnetId --public-ip-address '""""' --nsg '""""'"
$vmCreate = if ($osTypeWindows) {"$vmCreate --admin-password $($virtualMachine.adminLogin.userPassword)"} else {"$vmCreate --ssh-key-values $($virtualMachine.adminLogin.sshKeyPublic)"}
Invoke-Expression -Command $vmCreate

###############
# Render Farm #
###############

$osTypeWindows     = $false
$extendedLocation  = $false
$resourceGroupName = "AAA"
$resourceLocation = @{
  regionName       = if ($extendedLocation) {"WestUS"} else {"SouthCentralUS"}
  extendedZoneName = "LosAngeles"
}
$virtualNetwork = @{
  subscriptionId    = az account show --query id --output tsv
  resourceGroupName = "ArtistAnywhere.Network.$($resourceLocation.regionName)$(if ($extendedLocation) {".$($resourceLocation.extendedZoneName)"})"
  name              = "Studio"
  subnetName        = "Farm"
}
$virtualMachine = @{
  name    = if ($osTypeWindows) {"WinFarm"} else {"LnxFarm"}
  size    = "Standard_HB176rs_v4" # "Standard_NV72ads_A10_v5"
  imageId = if ($osTypeWindows) {"MicrosoftWindowsDesktop:Windows-10:Win10-22H2-Ent-G2:Latest"} else {"RESF:RockyLinux-x86_64:9-Base:9.3.20231113"}
  adminLogin = @{
    userName     = az keyvault secret show --vault-name "xstudio" --name "AdminUsername" --query value --output tsv
    userPassword = az keyvault secret show --vault-name "xstudio" --name "AdminPassword" --query value --output tsv
    sshKeyPublic = az keyvault secret show --vault-name "xstudio" --name "SSHKeyPublic" --query value
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
az group create --name $resourceGroupName --location $resourceLocation.regionName
$extendedZone = if ($extendedLocation) {" --edge-zone $($resourceLocation.extendedZoneName)"} else {""}
$priority = if ($virtualMachine.spot.enable) {"Spot"} else {"Regular"}
$subnetId = "/subscriptions/$($virtualNetwork.subscriptionId)/resourceGroups/$($virtualNetwork.resourceGroupName)/providers/Microsoft.Network/virtualNetworks/$($virtualNetwork.name)/subnets/$($virtualNetwork.subnetName)"
$vmCreate = "az vm create --resource-group $resourceGroupName$extendedZone --name $($virtualMachine.name) --size $($virtualMachine.size) --os-disk-size-gb $($virtualMachine.osDisk.sizeGB) --os-disk-caching $($virtualMachine.osDisk.caching) --image $($virtualMachine.imageId) --admin-username $($virtualMachine.adminLogin.userName) --subnet $subnetId --public-ip-address '""""' --nsg '""""' --priority $priority"
$vmCreate = if ($osTypeWindows) {"$vmCreate --admin-password $($virtualMachine.adminLogin.userPassword)"} else {"$vmCreate --ssh-key-values $($virtualMachine.adminLogin.sshKeyPublic)"}
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
  regionName       = if ($extendedLocation) {"WestUS"} else {"SouthCentralUS"}
  extendedZoneName = "LosAngeles"
}
$virtualNetwork = @{
  subscriptionId    = az account show --query id --output tsv
  resourceGroupName = "ArtistAnywhere.Network.$($resourceLocation.regionName)$(if ($extendedLocation) {".$($resourceLocation.extendedZoneName)"})"
  name              = "Studio"
  subnetName        = "Workstation"
}
$virtualMachine = @{
  name    = if ($osTypeWindows) {"WinArtist"} else {"LnxArtist"}
  size    = "Standard_NV72ads_A10_v5" # "Standard_NG32ads_V620_v1"
  imageId = if ($osTypeWindows) {"MicrosoftWindowsDesktop:Windows-11:Win11-23H2-Ent:Latest"} else {"RESF:RockyLinux-x86_64:9-Base:9.3.20231113"}
  adminLogin = @{
    userName     = az keyvault secret show --vault-name "xstudio" --name "AdminUsername" --query value --output tsv
    userPassword = az keyvault secret show --vault-name "xstudio" --name "AdminPassword" --query value --output tsv
    sshKeyPublic = az keyvault secret show --vault-name "xstudio" --name "SSHKeyPublic" --query value
  }
  osDisk = @{
    sizeGB  = 1024
    caching = "ReadOnly"
  }
  hibernation = @{
    enable = $false
  }
}
az group create --name $resourceGroupName --location $resourceLocation.regionName
$extendedZone = if ($extendedLocation) {" --edge-zone $($resourceLocation.extendedZoneName)"} else {""}
$subnetId = "/subscriptions/$($virtualNetwork.subscriptionId)/resourceGroups/$($virtualNetwork.resourceGroupName)/providers/Microsoft.Network/virtualNetworks/$($virtualNetwork.name)/subnets/$($virtualNetwork.subnetName)"
$vmCreate = "az vm create --resource-group $resourceGroupName$extendedZone --name $($virtualMachine.name) --size $($virtualMachine.size) --os-disk-size-gb $($virtualMachine.osDisk.sizeGB) --os-disk-caching $($virtualMachine.osDisk.caching) --image $($virtualMachine.imageId) --admin-username $($virtualMachine.adminLogin.userName) --subnet $subnetId --public-ip-address '""""' --nsg '""""'"
$vmCreate = if ($osTypeWindows) {"$vmCreate --admin-password $($virtualMachine.adminLogin.userPassword)"} else {"$vmCreate --ssh-key-values $($virtualMachine.adminLogin.sshKeyPublic)"}
Invoke-Expression -Command $vmCreate
