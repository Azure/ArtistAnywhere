https://download.rockylinux.org/vault/

az vm image list --publisher RESF --offer Rocky --all --edge-zone LosAngeles

az vm image list --publisher RESF --offer RockyLinux-x86_64 --sku 8-Base --all --edge-zone LosAngeles
uname -r
4.18.0-513.5.1.el8_9.x86_64

az vm image list --publisher MicrosoftWindowsServer --offer WindowsServer --sku 2022-Datacenter-Azure-Edition --all --edge-zone LosAngeles
az vm image list --publisher MicrosoftWindowsDesktop --offer Windows-10 --sku Win10-22H2-Ent-G2 --all --edge-zone LosAngeles
az vm image list --publisher MicrosoftWindowsDesktop --offer Windows-11 --sku Win11-23H2-Ent --all --edge-zone LosAngeles

az vm image list --publisher Microsoft-Avere --offer vFXT --sku Avere-vFXT-Controller --all # 2023.09.0
az vm image list --publisher Microsoft-Avere --offer vFXT --sku Avere-vFXT-Node --all       # 2023.09.1
