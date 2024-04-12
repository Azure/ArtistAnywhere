$tenantId       = ""
$subscriptionId = ""
az login --tenant $tenantId
az account set --subscription $subscriptionId
az account show

az account list-locations --query "[?name=='losangeles']" --include-extended-locations
az account list-locations --query "[?name=='westus']"
az account list-locations --query "[?name=='westus2']"
az account list-locations --query "[?name=='westus3']"

az account list-locations --query "[?name=='westus']|[0]"
{
  "availabilityZoneMappings": [
    {
      "logicalZone": "1",
      "physicalZone": "westus-az1"
    },
    {
      "logicalZone": "2",
      "physicalZone": "westus-az2"
    },
    {
      "logicalZone": "3",
      "physicalZone": "westus-az3"
    }
  ],
  "displayName": "West US",
  "id": "/subscriptions/5cc0d8f1-3643-410c-8646-1a2961134bd3/locations/westus",
  "metadata": {
    "geography": "United States",
    "geographyGroup": "US",
    "latitude": "37.783",
    "longitude": "-122.417",
    "pairedRegion": [
      {
        "id": "/subscriptions/5cc0d8f1-3643-410c-8646-1a2961134bd3/locations/eastus",
        "name": "eastus"
      }
    ],
    "physicalLocation": "California",
    "regionCategory": "Other",
    "regionType": "Physical"
  },
  "name": "westus",
  "regionalDisplayName": "(US) West US",
  "type": "Region"
}

az account list-locations --query [].[metadata.regionType,name,metadata.pairedRegion[0].name] --output table
