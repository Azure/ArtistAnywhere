https://repo.almalinux.org/vault/

az vm image list --publisher AlmaLinux --offer AlmaLinux-x86_64 --sku 8-Gen2 --all
uname -r
4.18.0-477.15.1.el8_8.x86_64

dnf -y upgrade
4.18.0-513.5.1.el8_9.x86_64

https://download.rockylinux.org/vault/

az vm image list --publisher CIQ --offer Rocky --sku Rocky-8 --all
az vm image list --publisher CIQ --offer Rocky --sku Rocky-9 --all

az vm image list --publisher CIQ --offer Rocky --sku Rocky-8-6 --all
4.18.0-372.16.1.el8_6.0.1.x86_64

az vm image list --publisher MicrosoftWindowsServer --offer WindowsServer --sku 2022-Datacenter-G2 --all
az vm image list --publisher MicrosoftWindowsDesktop --offer Windows-10 --sku Win10-22H2-Pro-G2 --all
az vm image list --publisher MicrosoftWindowsDesktop --offer Windows-11 --sku Win11-23H2-Pro --all

az vm image list --publisher Microsoft-Avere --offer vFXT --sku Avere-vFXT-Controller --all # 2023.09.0
az vm image list --publisher Microsoft-Avere --offer vFXT --sku Avere-vFXT-Node --all       # 2023.09.1
