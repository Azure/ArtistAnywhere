$regionName = "WestUS2"
az batch location list-skus --location $regionName --output table

$queryFilter = "[? imageReference.publisher == 'almalinux' && nodeAgentSkuId=='batch.node.el 8']"
az batch pool supported-images list --query $queryFilter

$queryFilter = "[? imageReference.publisher == 'almalinux' && nodeAgentSkuId=='batch.node.el 9']"
az batch pool supported-images list --query $queryFilter

$queryFilter = "[? nodeAgentSkuId == 'batch.node.windows amd64']"
az batch pool supported-images list --query $queryFilter

$queryFilter = "[? capabilities != null] | [? contains(capabilities, 'DockerCompatible')]"
az batch pool supported-images list --query $queryFilter

$resourceGroupName = "ArtistAnywhere.Farm.West"
$accountName       = "xstudio"
az batch account login --resource-group $resourceGroupName --name $accountName

$poolId = "LnxFarmC"
az batch pool show --pool-id $poolId
az batch node list --pool-id $poolId
