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
  name              = "Studio-West"
  subnetName        = "Farm"
}
$virtualMachine = @{
  name    = if ($osTypeWindows) {"WinFarmC"} else {"LnxFarmC"}
  size    = "Standard_D64s_v4" # "Standard_HB120rs_v2"
  count   = 2
  imageId = if ($osTypeWindows) {"MicrosoftWindowsDesktop:Windows-10:Win10-22H2-Ent-G2:Latest"} else {"RESF:RockyLinux-x86_64:8-Base:Latest"}
  adminLogin = @{
    username = "xadmin"
    password = "P@ssword1234"
  }
  osDisk = @{
    sizeGB  = 480
    caching = "ReadOnly"
    ephemeral = @{
      enable    = $false
      placement = "ResourceDisk"
    }
  }
  spot = @{
    enable         = $true
    evictionPolicy = "Delete"
  }
  flexMode = @{
    enable = $true
  }
  faultDomainCount = 1
}
az group create --name $resourceGroupName --location $resourceLocation.region
$edgeZone = if ($extendedLocation) {" --edge-zone $($resourceLocation.edgeZone)"} else {""}
$priority = if ($virtualMachine.spot.enable) {"Spot"} else {"Regular"}
$subnetId = "/subscriptions/$($virtualNetwork.subscriptionId)/resourceGroups/$($virtualNetwork.resourceGroupName)/providers/Microsoft.Network/virtualNetworks/$($virtualNetwork.name)/subnets/$($virtualNetwork.subnetName)"
$vmCreate = "az vmss create --resource-group $resourceGroupName$edgeZone --name $($virtualMachine.name) --vm-sku $($virtualMachine.size) --instance-count $($virtualMachine.count) --platform-fault-domain-count $($virtualMachine.faultDomainCount) --os-disk-size-gb $($virtualMachine.osDisk.sizeGB) --os-disk-caching $($virtualMachine.osDisk.caching) --image $($virtualMachine.imageId.ToLower()) --admin-username $($virtualMachine.adminLogin.username) --admin-password $($virtualMachine.adminLogin.password) --subnet $subnetId --public-ip-address '""""' --nsg '""""' --lb '""""' --priority $priority"
$vmCreate = if ($virtualMachine.osDisk.ephemeral.enable) {"$vmCreate --ephemeral-os-disk $($virtualMachine.osDisk.ephemeral.enable) --ephemeral-os-disk-placement $($virtualMachine.osDisk.ephemeral.placement)"} else {$vmCreate}
$vmCreate = if ($virtualMachine.spot.enable) {"$vmCreate --eviction-policy $($virtualMachine.spot.evictionPolicy)"} else {$vmCreate}
$vmCreate = "$vmCreate --orchestration-mode $(if ($($virtualMachine.flexMode.enable)) {"Flexible"} else {"Uniform"}) --single-placement-group false"
Invoke-Expression -Command $vmCreate
