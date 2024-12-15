####################################################################################################################
# CycleCloud Workspace for Slurm (CCWS) (https://learn.microsoft.com/azure/cyclecloud/how-to/ccws/deploy-with-cli) #
####################################################################################################################

$imagePublisher = "AzureCycleCloud"
$imageOffer     = "Azure-CycleCloud"
$imagePlan      = "CycleCloud8-Gen2"

az vm image terms show --publisher $imagePublisher --offer $imageOffer --plan $imagePlan
az vm image terms accept --publisher $imagePublisher --offer $imageOffer --plan $imagePlan

az vm image list --publisher $imagePublisher --offer $imageOffer --sku $imagePlan --all

git clone --branch release https://github.com/Azure/cyclecloud-slurm-workspace.git

$regionName     = "SouthCentralUS"
$deploymentName = "CycleCloud-Slurm-Workspace"
$templateFile   = "../../cyclecloud-slurm-workspace-release/bicep/mainTemplate.bicep"
$parameterFile  = "parameters.linux.json"

az account show
az deployment sub create --name $deploymentName --location $regionName --template-file $templateFile --parameters $parameterFile

cd cyclecloud-slurm-workspace
./util/delete_roles.sh --resource-group ArtistAnywhere.CCWS --delete-resource-group

##############################################################################################################################
# CycleCloud Portal Bastion Tunnel (https://learn.microsoft.com/azure/cyclecloud/how-to/ccws/connect-to-portal-with-bastion) #
##############################################################################################################################

$subscriptionId     = az account show --query id --output tsv
$resourceGroupName  = "ArtistAnywhere.CCWS"
$virtualMachineName = "ccw-cyclecloud-vm"
$cycleCloud = @{
  resourceId   = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Compute/virtualMachines/$virtualMachineName"
  resourcePort = 443
  tunnelPort   = 8443
}
$bastion = @{
  name              = "Bastion-Studio"
  resourceGroupName = "ArtistAnywhere.Network.SouthCentralUS"
}

az network bastion tunnel --name $bastion.name --resource-group $bastion.resourceGroupName --target-resource-id $cycleCloud.resourceId --resource-port $cycleCloud.resourcePort --port $cycleCloud.tunnelPort

########################################################################################################################
# Login Node Bastion SSH (https://learn.microsoft.com/azure/cyclecloud/how-to/ccws/connect-to-login-node-with-bastion) #
########################################################################################################################

$subscriptionId     = az account show --query id --output tsv
$resourceGroupName  = "ArtistAnywhere.CCWS"
$virtualMachineName = "ccw-cyclecloud-vm"
$cycleCloud = @{
  resourceId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Compute/virtualMachines/$virtualMachineName"
  authType   = "ssh-key"
  userName   = "hpcadmin"
  sshKeyFile = "~/.ssh/hpcadmin_id_rsa"
}
$bastion = @{
  name              = "Bastion-Studio"
  resourceGroupName = "ArtistAnywhere.Network.SouthCentralUS"
}

az network bastion ssh --name $bastion.name --resource-group $bastion.resourceGroupName --target-resource-id $cycleCloud.resourceId --auth-type $cycleCloud.authType --username $cycleCloud.userName --ssh-key $cycleCloud.sshKeyFile
