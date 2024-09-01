###############
# Render Farm #
###############

$osTypeWindows     = $false
$extendedLocation  = $false
$resourceGroupName = "AAA"
$resourceLocation = @{
  region       = if ($extendedLocation) {"WestUS"} else {"SouthCentralUS"}
  extendedZone = "LosAngeles"
}
$virtualNetwork = @{
  subscriptionId    = az account show --query id --output tsv
  resourceGroupName = "ArtistAnywhere.Network.$($resourceLocation.region)$(if ($extendedLocation) {".$($resourceLocation.extendedZone)"})"
  name              = "Studio"
  subnetName        = "Farm"
}
$virtualMachine = @{
  name    = if ($osTypeWindows) {"WinFarmC"} else {"LnxFarmC"}
  size    = "Standard_HB176rs_v4"
  count   = 2
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
      enable    = $false
      placement = "ResourceDisk"
    }
  }
  spot = @{
    enable         = $true
    evictionPolicy = "Delete"
  }
  flexMode = @{
    enable = $false
  }
  singlePlacementGroup = $false
  faultDomainCount     = 1
}
az group create --name $resourceGroupName --location $resourceLocation.region
$extendedZone = if ($extendedLocation) {" --edge-zone $($resourceLocation.extendedZone)"} else {""}
$priority = if ($virtualMachine.spot.enable) {"Spot"} else {"Regular"}
$subnetId = "/subscriptions/$($virtualNetwork.subscriptionId)/resourceGroups/$($virtualNetwork.resourceGroupName)/providers/Microsoft.Network/virtualNetworks/$($virtualNetwork.name)/subnets/$($virtualNetwork.subnetName)"
$vmCreate = "az vmss create --resource-group $resourceGroupName$extendedZone --name $($virtualMachine.name) --vm-sku $($virtualMachine.size) --instance-count $($virtualMachine.count) --os-disk-size-gb $($virtualMachine.osDisk.sizeGB) --os-disk-caching $($virtualMachine.osDisk.caching) --image $($virtualMachine.imageId.ToLower()) --admin-username $($virtualMachine.adminLogin.userName) --subnet $subnetId --public-ip-address '""""' --nsg '""""' --lb '""""' --priority $priority"
$vmCreate = if ($osTypeWindows) {"$vmCreate --admin-password $($virtualMachine.adminLogin.userPassword)"} else {"$vmCreate --ssh-key-values $($virtualMachine.adminLogin.sshKeyPublic)"}
$vmCreate = if ($virtualMachine.osDisk.ephemeral.enable) {"$vmCreate --ephemeral-os-disk $($virtualMachine.osDisk.ephemeral.enable) --ephemeral-os-disk-placement $($virtualMachine.osDisk.ephemeral.placement)"} else {$vmCreate}
$vmCreate = if ($virtualMachine.spot.enable) {"$vmCreate --eviction-policy $($virtualMachine.spot.evictionPolicy)"} else {$vmCreate}
$vmCreate = "$vmCreate --orchestration-mode $(if ($($virtualMachine.flexMode.enable)) {"Flexible"} else {"Uniform"}) --single-placement-group $($virtualMachine.singlePlatformGroup) --platform-fault-domain-count $($virtualMachine.faultDomainCount)"
Invoke-Expression -Command $vmCreate
