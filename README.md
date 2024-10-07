# Azure Artist Anywhere (AAA) Deployment Framework

Azure Artist Anywhere (AAA) is a *modular & flexible* [Infrastructure as Code (IaC)](https://learn.microsoft.com/devops/deliver/what-is-infrastructure-as-code) solution deployment framework for<br/>[Azure High-Performance Computing (HPC)](https://azure.microsoft.com/solutions/high-performance-computing) workloads. Enable remote artist productivity with [global Azure scale](https://azure.microsoft.com/global-infrastructure) via<br/>[Compute Fleet](https://learn.microsoft.com/azure/azure-compute-fleet/overview) AI-enabled deployments with up to 10,000 [Spot](https://learn.microsoft.com/azure/virtual-machines/spot-vms) / [Standard VMs](https://learn.microsoft.com/azure/virtual-machines/overview) and up to 15 [VM sizes](https://learn.microsoft.com/azure/virtual-machines/sizes/overview) per request.

The following solution design principles and features are implemented throughout the AAA deployment framework.
* Defense-in-depth layered security with integration of core services including [Managed Identity](https://learn.microsoft.com/entra/identity/managed-identities-azure-resources/overview), [Key Vault](https://learn.microsoft.com/azure/key-vault/general/overview),</br>[Private Link](https://learn.microsoft.com/azure/private-link/private-link-overview) / [ Endpoints](https://learn.microsoft.com/azure/private-link/private-endpoint-overview), [Network Security Groups](https://learn.microsoft.com/azure/virtual-network/network-security-groups-overview), [NAT Gateway](https://learn.microsoft.com/azure/nat-gateway/nat-overview), [Bastion](https://learn.microsoft.com/azure/bastion/bastion-overview), [Policy](https://learn.microsoft.com/azure/governance/policy/overview), [Defender for Cloud](https://learn.microsoft.com/azure/defender-for-cloud/defender-for-cloud-introduction), etc
* Any 3<sup>rd</sup>-party or custom software (e.g., job scheduler) is supported in a custom image [Compute Gallery](https://learn.microsoft.com/azure/virtual-machines/shared-image-galleries)
* Integration of [Microsoft Cost Management](https://learn.microsoft.com/azure/cost-management-billing/costs/overview-cost-management) across all AAA-deployed Azure resource groups / services
* Multi-Region and [Extended Zone](https://learn.microsoft.com/azure/extended-zones/overview) deployments are supported via a [Virtual Network](https://learn.microsoft.com/azure/virtual-network/virtual-networks-overview) per region / zone
* Clean separation of [Terraform](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs) configuration files (**config.auto.tfvars**) and implementation files (**\*.tf**)

| **Module Name** | **Module Description** | **Required for<br/>Burst Compute?** | **Required for<br/>Full Solution?<br/>(*Compute & Storage*)** |
| - | - | - | - |
| [0&#160;Global&#160;Foundation](https://github.com/Azure/ArtistAnywhere/tree/main/0.Global.Foundation) | Defines&#160;global&#160;config&#160;([Azure&#160;Region](https://azure.microsoft.com/regions)) and core services ([Terraform Storage](https://developer.hashicorp.com/terraform/language/settings/backends/azurerm), [Managed Identity](https://learn.microsoft.com/entra/identity/managed-identities-azure-resources/overview), [Key Vault](https://learn.microsoft.com/azure/key-vault/general/overview), etc) | Yes | Yes |
| [1 Virtual Network](https://github.com/Azure/ArtistAnywhere/tree/main/1.Virtual.Network) | Deploys [Virtual Network](https://learn.microsoft.com/azure/virtual-network/virtual-networks-overview) with [VPN](https://learn.microsoft.com/azure/vpn-gateway/vpn-gateway-about-vpngateways)<br/>or [ExpressRoute](https://learn.microsoft.com/azure/expressroute/expressroute-about-virtual-network-gateways) gateway services | Yes,&#160;if&#160;[Virtual&#160;Network](https://learn.microsoft.com/azure/virtual-network/virtual-networks-overview) is not yet deployed | Yes,&#160;if&#160;[Virtual&#160;Network](https://learn.microsoft.com/azure/virtual-network/virtual-networks-overview) is not yet deployed |
| [2 Image Builder](https://github.com/Azure/ArtistAnywhere/tree/main/2.Image.Builder) | Deploys [Image Builder](https://learn.microsoft.com/azure/virtual-machines/image-builder-overview) and [Compute Gallery](https://learn.microsoft.com/azure/virtual-machines/shared-image-galleries) with image customize scripts | No, use your custom image config [here](https://github.com/Azure/ArtistAnywhere/tree/main/6.Compute.Farm/config.auto.tfvars#L15) | No, use your custom image config [here](https://github.com/Azure/ArtistAnywhere/tree/main/6.Compute.Farm/config.auto.tfvars#L15) |
| [3 File Storage](https://github.com/Azure/ArtistAnywhere/tree/main/3.File.Storage) | Deploys native ([Blob [NFS]](https://learn.microsoft.com/azure/storage/blobs/network-file-system-protocol-support), [Files](https://learn.microsoft.com/azure/storage/files/storage-files-introduction), [NetApp Files](https://learn.microsoft.com/azure/azure-netapp-files/azure-netapp-files-introduction), [Qumulo](https://learn.microsoft.com/azure/partner-solutions/qumulo/qumulo-overview), [Lustre](https://learn.microsoft.com/azure/azure-managed-lustre/amlfs-overview)) or hosted ([Weka](https://azuremarketplace.microsoft.com/marketplace/apps/weka1652213882079.weka_data_platform)) storage services | No, use your current NAS via [4 File Cache](https://github.com/Azure/ArtistAnywhere/tree/main/4.File.Cache) | Yes |
| [4 File Cache](https://github.com/Azure/ArtistAnywhere/tree/main/4.File.Cache) | Deploys [Hammerspace](https://azuremarketplace.microsoft.com/marketplace/apps/hammerspace.hammerspace-byol), [HPC Cache](https://learn.microsoft.com/azure/hpc-cache/hpc-cache-overview) or [Avere vFXT](https://learn.microsoft.com/azure/avere-vfxt/avere-vfxt-overview) for scalable caching | Yes | No |
| [5 Job Scheduler](https://github.com/Azure/ArtistAnywhere/tree/main/5.Job.Scheduler) | Deploys [Virtual Machines](https://learn.microsoft.com/azure/virtual-machines) for compute job scheduling and management | No | No |
| [6 Compute Farm](https://github.com/Azure/ArtistAnywhere/tree/main/6.Compute.Farm) | Deploys [Compute Fleet](https://learn.microsoft.com/azure/azure-compute-fleet/overview) or [VM Scale Sets](https://learn.microsoft.com/azure/virtual-machine-scale-sets/overview) for scalable compute farms | Yes | Yes |
| [7&#160;Artist&#160;Workstation](https://github.com/Azure/ArtistAnywhere/tree/main/7.Artist.Workstation) | Deploys [Virtual Machines](https://learn.microsoft.com/azure/virtual-machines/overview) for remote artist workstations with [HP Anyware](https://www.teradici.com/products/hp-anyware) | No | No |

## Local Installation Process

The following local installation process is required for deployment orchestration.

1. Make sure the [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) is installed locally and accessible in your PATH environment variable.
1. Make sure the [Terraform CLI](https://developer.hashicorp.com/terraform/downloads) is installed locally and accessible in your PATH environment variable.
1. Clone this GitHub repository to your local workstation for module configuration and deployment orchestration.

## Module Configuration & Deployment

For each module, here is the recommended configuration and deployment process.

1. Review and edit the config values in each `config.auto.tfvars` file for your target deployment.
   * In module `0 Global Foundation`, review and edit the following required config files.<br/>For example, your Azure subscription id **must** be set in the `/cfg/global.tf` file
      * `/cfg/global.tf` - defines global config (subscription id, default region name, etc)
      * `/cfg/file.system.tf` - defines the active file system(s) for compute node mount
      * `/cfg/backend.config` - defines Terraform backend state file Azure Blob storage
   * In modules `2 Image Builder`, `5 Job Scheduler` and `7 Artist Workstation`, make sure you have sufficient **Standard** compute cores quota available on your Azure subscription for each configured virtual machine type / size in your target region.
   * In module `6 Compute Farm`, make sure you have sufficient [Spot](https://learn.microsoft.com/azure/virtual-machines/spot-vms) compute cores quota available on your Azure subscription for each configured virtual machine type / size in your target region.
   * In modules `5 Job Scheduler`, `6 Compute Farm` and `7 Artist Workstation`, make sure each **image** config references the correct [Compute Gallery](https://learn.microsoft.com/azure/virtual-machines/shared-image-galleries) custom image in your Azure subscription.
1. In module `0 Global Foundation`, run `terraform init` to initialize the module local directory (append `-upgrade` if older providers are detected).
1. In all modules except `0 Global Foundation`, run `terraform init -backend-config ../0.Global.Foundation/cfg/backend.config` to initialize the module local directory (append `-upgrade` if older providers are detected).
1. Run `terraform apply` to generate the Terraform deployment [Plan](https://www.terraform.io/docs/cli/run/index.html#planning) (append `-destroy` to delete Azure resources).
1. Review the Terraform deployment Plan *before* confirming to add, change and/or destroy Azure resources.
   * In module `2 Image Builder`,
      * The following Azure Marketplace Rocky Linux image terms must be accepted on your Azure subscription.<br/>`az vm image terms accept --publisher RESF --offer RockyLinux-x86_64 --plan 9-Base`
      * Use the Azure management portal or [Image Builder CLI](https://learn.microsoft.com/cli/azure/image/builder#az-image-builder-run) to start image build runs as needed.

## Render Job Samples

The following sample images were rendered on Azure via multiple render farm, engine and job submission options.

### [Disney Moana Island](https://www.disneyanimation.com/resources/moana-island-scene)

The following Disney Moana Island scene was rendered on Azure via the [Physically-Based Ray Tracer (PBRT)](https://github.com/mmp/pbrt-v4) renderer.

![moana-island](https://github.com/Azure/ArtistAnywhere/assets/22285652/7320acaf-061d-40a5-95e8-3a157a0a513c)

To render the Disney Moana Island scene on an Azure **Linux** render farm, the following job submission command can be submitted from a **Linux** or **Windows** artist workstation.

```deadlinecommand -SubmitCommandLineJob -name moana-island -executable pbrt -arguments "--outfile /mnt/storage/pbrt/moana/island-v4.png /mnt/storage/pbrt/moana/island/pbrt-v4/island.pbrt"```

To render the Disney Moana Island scene on an Azure **Windows** render farm, the following job submission command can be submitted from a **Linux** or **Windows** artist workstation.

```deadlinecommand -SubmitCommandLineJob -name moana-island -executable pbrt.exe -arguments "--outfile X:\pbrt\moana\island-v4.png X:\pbrt\moana\island\pbrt-v4\island.pbrt"```

### [Blender Splash Screen](https://www.blender.org/download/demo-files/#splash)

The following Blender 3.4 Splash screen was rendered on Azure via the [Blender](https://www.blender.org) renderer.

![blender-splash](https://github.com/Azure/ArtistAnywhere/assets/22285652/07576415-ba75-454f-90b6-04f20cfecbe2)

To render the Blender Splash screen on an Azure **Linux** render farm, the following job submission command can be submitted from a **Linux** or **Windows** artist workstation.

```deadlinecommand -SubmitCommandLineJob -name blender-splash -executable blender -arguments "--background /mnt/storage/blender/3.4/splash.blend --render-output /mnt/storage/blender/3.4/splash --enable-autoexec --render-frame 1"```

To render the Blender Splash screen on an Azure **Windows** render farm, the following job submission command can be submitted from a **Linux** or **Windows** artist workstation.

```deadlinecommand -SubmitCommandLineJob -name blender-splash -executable blender.exe -arguments "--background X:\blender\3.4\splash.blend --render-output X:\blender\3.4\splash --enable-autoexec --render-frame 1"```

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft
trademarks or logos is subject to and must follow
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.
