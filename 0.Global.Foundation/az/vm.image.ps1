#########
# Linux #
#########

$publisher = "RESF"
$offer     = "RockyLinux-x86_64"
$plan      = "8-Base"

az vm image list --publisher $publisher --offer $offer --sku $plan --all --edge-zone LosAngeles
uname -r
4.18.0-513.5.1.el8_9.x86_64

az vm image terms show --publisher $publisher --offer $offer --plan $plan
az vm image terms accept --publisher $publisher --offer $offer --plan $plan

https://download.rockylinux.org/vault/

###########
# Windows #
###########

az vm image list --publisher MicrosoftWindowsServer --offer WindowsServer --sku 2022-Datacenter-Azure-Edition --all --edge-zone LosAngeles
az vm image list --publisher MicrosoftWindowsDesktop --offer Windows-10 --sku Win10-22H2-Ent-G2 --all --edge-zone LosAngeles
az vm image list --publisher MicrosoftWindowsDesktop --offer Windows-11 --sku Win11-23H2-Ent --all --edge-zone LosAngeles

##############
# CycleCloud #
##############

az vm image list --publisher AzureCycleCloud --offer Azure-CycleCloud --sku CycleCloud8-Gen2 --all

#########
# Avere #
#########

$publisher      = "Microsoft-Avere"
$offer          = "vFXT"
$planController = "Avere-vFXT-Controller"
$planNode       = "Avere-vFXT-Node"

az vm image list --publisher $publisher --offer $offer --sku $planController --all # 2023.09.0
az vm image list --publisher $publisher --offer $offer --sku $planNode --all       # 2023.09.1

az vm image terms show --publisher $publisher --offer $offer --plan $planController
az vm image terms accept --publisher $publisher --offer $offer --plan $planController

az vm image terms show --publisher $publisher --offer $offer --plan $planNode
az vm image terms accept --publisher $publisher --offer $offer --plan $planNode

###############
# Hammerspace #
###############

$publisher = "Hammerspace"
$offer     = "Hammerspace-4-6-5-BYOL"
$plan      = "PlanForMACC-BYOL"

az vm image list --publisher $publisher --offer $offer --sku $plan --all

az vm image terms show --publisher $publisher --offer $offer --plan $plan
az vm image terms accept --publisher $publisher --offer $offer --plan $plan
