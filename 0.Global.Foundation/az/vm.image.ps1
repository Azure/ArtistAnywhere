#########
# Linux #
#########

$publisher = "RESF"
$offer     = "RockyLinux-x86_64"
$plan      = "9-Base"
az vm image list --publisher $publisher --offer $offer --sku $plan --all --edge-zone LosAngeles
[
  {
    "architecture": "x64",
    "offer": "rockylinux-x86_64",
    "publisher": "resf",
    "sku": "9-base",
    "urn": "resf:rockylinux-x86_64:9-base:9.3.20231113",
    "version": "9.3.20231113"
  }
]
uname -r
5.14.0-362.8.1.el9_3.x86_64

az vm image terms show --publisher $publisher --offer $offer --plan $plan
az vm image terms accept --publisher $publisher --offer $offer --plan $plan

https://download.rockylinux.org/vault/

###########
# Windows #
###########

az vm image list --publisher MicrosoftWindowsServer --offer WindowsServer --sku 2022-Datacenter-Azure-Edition --all --edge-zone LosAngeles
az vm image list --publisher MicrosoftWindowsDesktop --offer Windows-10 --sku Win10-22H2-Ent-G2 --all --edge-zone LosAngeles
az vm image list --publisher MicrosoftWindowsDesktop --offer Windows-11 --sku Win11-23H2-Ent --all --edge-zone LosAngeles

###############
# Hammerspace #
###############

$publisher = "Hammerspace"
$offer     = "Hammerspace_BYOL_5_0"
$plan      = "Hammerspace_5_0"

az vm image list --publisher $publisher --offer $offer --sku $plan --all
[
  {
    "architecture": "x64",
    "offer": "hammerspace_byol_5_0",
    "publisher": "hammerspace",
    "sku": "hammerspace_5_0",
    "urn": "hammerspace:hammerspace_byol_5_0:hammerspace_5_0:24.05.21",
    "version": "24.05.21"
  },
  {
    "architecture": "x64",
    "offer": "hammerspace_byol_5_0",
    "publisher": "hammerspace",
    "sku": "hammerspace_5_0",
    "urn": "hammerspace:hammerspace_byol_5_0:hammerspace_5_0:24.06.19",
    "version": "24.06.19"
  }
]

az vm image terms show --publisher $publisher --offer $offer --plan $plan
az vm image terms accept --publisher $publisher --offer $offer --plan $plan

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

az vm image list --publisher $publisher --offer $offer --sku $planController --all # 2024.08.28
az vm image list --publisher $publisher --offer $offer --sku $planNode --all       # 2024.04.1

az vm image terms show --publisher $publisher --offer $offer --plan $planController
az vm image terms accept --publisher $publisher --offer $offer --plan $planController

az vm image terms show --publisher $publisher --offer $offer --plan $planNode
az vm image terms accept --publisher $publisher --offer $offer --plan $planNode
