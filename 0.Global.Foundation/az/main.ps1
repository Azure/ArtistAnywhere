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

az account list-locations --query "[?name=='southcentralus']"
[
  {
    "availabilityZoneMappings": [
      {
        "logicalZone": "1",
        "physicalZone": "southcentralus-az1"
      },
      {
        "logicalZone": "2",
        "physicalZone": "southcentralus-az2"
      },
      {
        "logicalZone": "3",
        "physicalZone": "southcentralus-az3"
      }
    ],
    "displayName": "South Central US",
    "id": "/subscriptions/5cc0d8f1-3643-410c-8646-1a2961134bd3/locations/southcentralus",
    "metadata": {
      "geography": "United States",
      "geographyGroup": "US",
      "latitude": "29.4167",
      "longitude": "-98.5",
      "pairedRegion": [
        {
          "id": "/subscriptions/5cc0d8f1-3643-410c-8646-1a2961134bd3/locations/northcentralus",
          "name": "northcentralus"
        }
      ],
      "physicalLocation": "Texas",
      "regionCategory": "Recommended",
      "regionType": "Physical"
    },
    "name": "southcentralus",
    "regionalDisplayName": "(US) South Central US",
    "type": "Region"
  }
]

az account list-locations --query "[?name=='southcentralus'].availabilityZoneMappings[].logicalZone"
[
  "1",
  "2",
  "3"
]

az account list-locations --query "[?name=='westus'].availabilityZoneMappings[].logicalZone"
[]
