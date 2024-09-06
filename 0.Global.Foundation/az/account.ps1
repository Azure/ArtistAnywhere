$tenantId = ""
az login --tenant $tenantId

$subscriptionId = ""
az account set --subscription $subscriptionId
az account show

az account list-locations --query "[?name=='southcentralus']"
az account list-locations --query "[?name=='losangeles']" --include-extended-locations
az account list-locations --query "[?name=='westus']"
az account list-locations --query "[?name=='westus2']"
az account list-locations --query "[?name=='eastus']"
az account list-locations --query "[?name=='eastus2']"

az account list-locations --query "[?name=='southcentralus'].availabilityZoneMappings[].logicalZone"
[
  "1",
  "2",
  "3"
]

az account list-locations --query "[?name=='westus'].availabilityZoneMappings[].logicalZone"
[]
