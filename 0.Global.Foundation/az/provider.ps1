# 2024-03-01-preview
az provider show --namespace Microsoft.DocumentDB --query "resourceTypes[?resourceType=='mongoClusters'].apiVersions[]"

# 2023-07-01
az provider show --namespace Microsoft.VirtualMachineImages --query "resourceTypes[?resourceType=='imageTemplates'].apiVersions[]"

# 2024-01-30-preview
az provider show --namespace Qumulo.Storage --query "resourceTypes[?resourceType=='fileSystems'].apiVersions[]"
