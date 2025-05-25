####################################################################################################################
# CycleCloud Workspace for Slurm (CCWS) (https://learn.microsoft.com/azure/cyclecloud/how-to/ccws/deploy-with-cli) #
####################################################################################################################

az account show

git clone --depth 1 --branch release https://github.com/Azure/cyclecloud-slurm-workspace.git

$regionName     = "SouthCentralUS"
$deploymentName = "CycleCloud.Workspace.Slurm"
$templateFile   = "../../cyclecloud-slurm-workspace/bicep/mainTemplate.bicep"
$parameterFile  = "parameters.json"
az deployment sub create --name $deploymentName --location $regionName --template-file $templateFile --parameters $parameterFile

# shell.azure.com
cd cyclecloud-slurm-workspace
resourceGroupName="AAA.Job.Manager.CCWS"
./util/delete_roles.sh --resource-group $resourceGroupName --delete-resource-group

##############################################################################################################################
# CycleCloud Portal Bastion Tunnel (https://learn.microsoft.com/azure/cyclecloud/how-to/ccws/connect-to-portal-with-bastion) #
##############################################################################################################################

$cycleCloud = @{
  machineName       = "ccw-cyclecloud-vm"
  resourceGroupName = "AAA.Job.Manager.CCWS"
  resourcePort      = 443
  tunnelPort        = 8443
}
$bastionHost = @{
  name              = "Bastion-Studio"
  resourceGroupName = "AAA.Network.SouthCentralUS"
}

$ccMachine = az vm show --resource-group $cycleCloud.resourceGroupName --name $cycleCloud.machineName --query id --output tsv
az network bastion tunnel --resource-group $bastionHost.resourceGroupName --name $bastionHost.name --target-resource-id $ccMachine --resource-port $cycleCloud.resourcePort --port $cycleCloud.tunnelPort

########################################################################################################################
# Login Node Bastion SSH (https://learn.microsoft.com/azure/cyclecloud/how-to/ccws/connect-to-login-node-with-bastion) #
########################################################################################################################

$loginNode = @{
  resourceGroupName = "AAA.Job.Manager.CCWS"
  authType          = "ssh-key"
  userName          = "hpcadmin"
  sshKeyFile        = "~/.ssh/id_rsa"
}
$bastionHost = @{
  name              = "Bastion-Studio"
  resourceGroupName = "AAA.Network.SouthCentralUS"
}

$loginVMSSName = az vmss list --resource-group $loginNode.resourceGroupName --query [0].name --output tsv
$loginInstance = az vmss list-instances --resource-group $loginNode.resourceGroupName --name $loginVMSSName --query [0].id --output tsv
az network bastion ssh --resource-group $bastionHost.resourceGroupName --name $bastionHost.name --target-resource-id $loginInstance --auth-type $loginNode.authType --username $loginNode.userName --ssh-key $loginNode.sshKeyFile
