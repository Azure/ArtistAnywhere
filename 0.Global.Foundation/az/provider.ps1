# 2024-07-01
az provider show --namespace Microsoft.NetApp --query "resourceTypes[?resourceType=='netAppAccounts/capacityPools'].apiVersions[]"
az provider show --namespace Microsoft.NetApp --query "resourceTypes[?resourceType=='netAppAccounts/capacityPools/volumes'].apiVersions[]"

# 2023-12-01
az provider show --namespace Microsoft.Web --query "resourceTypes[?resourceType=='serverFarms'].apiVersions[]"
az provider show --namespace Microsoft.Web --query "resourceTypes[?resourceType=='sites'].apiVersions[]"

# 2024-05-01-preview
az provider show --namespace Microsoft.AzureFleet --query "resourceTypes[?resourceType=='fleets'].apiVersions[]"
az provider show --namespace Microsoft.Network --query "resourceTypes[?resourceType=='virtualNetworks'].apiVersions[]" # 2024-03-01

# 2024-06-01-preview
az provider show --namespace Microsoft.VideoIndexer --query "resourceTypes[?resourceType=='accounts'].apiVersions[]"

# 2024-07-01
az provider show --namespace Microsoft.DocumentDB --query "resourceTypes[?resourceType=='mongoClusters'].apiVersions[]"

# 2020-03-01
az provider show --namespace Microsoft.StreamAnalytics --query "resourceTypes[?resourceType=='clusters'].apiVersions[]"

# 2024-02-01
az provider show --namespace Microsoft.VirtualMachineImages --query "resourceTypes[?resourceType=='imageTemplates'].apiVersions[]"

# 2024-06-19
az provider show --namespace Qumulo.Storage --query "resourceTypes[?resourceType=='fileSystems'].apiVersions[]"
