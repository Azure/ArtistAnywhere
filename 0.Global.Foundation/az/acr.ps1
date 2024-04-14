$registryName  = "xstudio"
$agentPoolName = "agents"

az acr agentpool list --registry $registryName

az acr agentpool create --registry $registryName --name $agentPoolName

az acr agentpool show --registry $registryName --name $agentPoolName

az acr agentpool delete --registry $registryName --name $agentPoolName
