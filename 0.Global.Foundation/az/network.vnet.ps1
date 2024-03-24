$resourceGroupName = "AAA"
$resourceLocation = @{
  region   = "WestUS"
  edgeZone = "LosAngeles"
}
$virtualNetwork = @{
  name        = "Studio-West"
  ipAddresses = "10.0.0.0/16"
  subnets = @(
    @{
      name        = "Farm"
      ipAddresses = "10.0.0.0/17"
      endpoints = @(
        "Microsoft.Storage.Global",
        "Microsoft.ContainerRegistry"
      )
    }
    @{
      name        = "Workstation"
      ipAddresses = "10.0.128.0/18"
      endpoints = @(
        "Microsoft.Storage.Global"
      )
    }
    @{
      name        = "Storage"
      ipAddresses = "10.0.192.0/24"
      endpoints = @(
        "Microsoft.Storage.Global"
      )
    }
    @{
      name        = "Data"
      ipAddresses = "10.0.195.0/24"
      endpoints = @(
      )
    }
    @{
      name        = "GatewaySubnet"
      ipAddresses = "10.0.255.0/26"
      endpoints = @(
      )
    }
    @{
      name        = "AzureBastionSubnet"
      ipAddresses = "10.0.255.64/26"
      endpoints = @(
      )
    }
  )
}
az group create --location $resourceLocation.region --name $resourceGroupName
az network vnet create --location $resourceLocation.region --edge-zone $resourceLocation.edgeZone --resource-group $resourceGroupName --name $virtualNetwork.name --address-prefix $virtualNetwork.ipAddresses
foreach ($subnet in $virtualNetwork.subnets) {
  $serviceEndpoints = "[]"
  if ($subnet.endpoints.length -gt 0) {
    $serviceEndpoints = "[{0}]" -f ($subnet.endpoints -join ",")
  }
  az network vnet subnet create --resource-group $resourceGroupName --name $subnet.name --address-prefixes $subnet.ipAddresses --vnet-name $virtualNetwork.name --service-endpoints "$serviceEndpoints"
}
