#######################################
# Query VM sku in a resource location #
#######################################

#$vmSku = "Standard_L8s_v3"
$vmSku = "Standard_HB120rs_v3"
#$vmSku = "Standard_HB176rs_v4"
#$vmSku = "Standard_HX176rs"
#$vmSku = "Standard_NV6ads_A10_v5"
#$vmSku = "Standard_NG8ads_V620_v1"

#$resourceLocation = "SouthCentralUS"
#$resourceLocation = "WestUS"
#$resourceLocation = "WestUS=LosAngeles"
#$resourceLocation = "WestUS2"
$resourceLocation = "WestUS3"
#$resourceLocation = "EastUS"
#$resourceLocation = "EastUS2"

$locationSkus = az vm list-skus --location $resourceLocation --resource-type "VirtualMachines" --all
$locationSkus = $locationSkus.Replace("Name", "name") | ConvertFrom-Json
$locationSkus | Where-Object ({ $_.name -eq $vmSku })

###########################################
# List locations (extended) with a VM sku #
###########################################

#$vmSku = "Standard_L8s_v3"
$vmSku = "Standard_HB120rs_v3"
#$vmSku = "Standard_HB176rs_v4"
#$vmSku = "Standard_HX176rs"
#$vmSku = "Standard_NV6ads_A10_v5"
#$vmSku = "Standard_NG8ads_V620_v1"

$locationsFilter = "[?contains(regionalDisplayName, '(US)')]"
#$locationsFilter = "[?contains(regionalDisplayName, '(Canada)')]"
#$locationsFilter = "[?contains(regionalDisplayName, '(South America)')]"

$skuLocations = @()
$locations = az account list-locations --query $locationsFilter --include-extended-locations | ConvertFrom-Json
foreach ($location in $locations) {
  $locationSkus = az vm list-skus --location $location.name --resource-type "VirtualMachines" --all
  $locationSkus = $locationSkus.Replace("Name", "name") | ConvertFrom-Json
  $locationSkus = $locationSkus | Where-Object ({ $_.name -eq $vmSku })
  if ($locationSkus) {
    $skuLocations += $location.name
  }
}
$skuLocations
