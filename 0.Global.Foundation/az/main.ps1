# 2023-12-01
az provider show --namespace Microsoft.Web --query "resourceTypes[?resourceType=='serverFarms'].apiVersions[]"
az provider show --namespace Microsoft.Web --query "resourceTypes[?resourceType=='sites'].apiVersions[]"

# 2024-05-01-preview
az provider show --namespace Microsoft.AzureFleet --query "resourceTypes[?resourceType=='fleets'].apiVersions[]"
az provider show --namespace Microsoft.Network --query "resourceTypes[?resourceType=='virtualNetworks'].apiVersions[]" # 2024-03-01

# 2024-06-01-preview
az provider show --namespace Microsoft.VideoIndexer --query "resourceTypes[?resourceType=='accounts'].apiVersions[]"

# 2024-06-01-preview
az provider show --namespace Microsoft.DocumentDB --query "resourceTypes[?resourceType=='mongoClusters'].apiVersions[]"

# 2020-03-01
az provider show --namespace Microsoft.StreamAnalytics --query "resourceTypes[?resourceType=='clusters'].apiVersions[]"

# 2024-02-01
az provider show --namespace Microsoft.VirtualMachineImages --query "resourceTypes[?resourceType=='imageTemplates'].apiVersions[]"

# 2024-06-19
az provider show --namespace Qumulo.Storage --query "resourceTypes[?resourceType=='fileSystems'].apiVersions[]"

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
