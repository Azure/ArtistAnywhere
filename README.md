# Azure Artist Anywhere (AAA) Deployment Framework

Azure Artist Anywhere (AAA) is a *modular & configurable* [Infrastructure as Code (IaC)](https://learn.microsoft.com/devops/deliver/what-is-infrastructure-as-code) solution deployment framework<br/>for [Azure HPC](https://azure.microsoft.com/solutions/high-performance-computing) Rendering & Visualization. Enable remote artist creativity and productivity with [global Azure scale](https://azure.microsoft.com/global-infrastructure) via<br/>[Compute Fleet](https://learn.microsoft.com/azure/azure-compute-fleet/overview) AI deployments with up to 10,000 [Spot](https://learn.microsoft.com/azure/virtual-machines/spot-vms) / [Standard VMs](https://learn.microsoft.com/azure/virtual-machines/overview) and up to 15 [VM sizes](https://learn.microsoft.com/azure/virtual-machines/sizes/overview) in a single request.

The following design principles are implemented throughout each AAA solution deployment framework module.
* Defense-in-depth layered security with integration of core services including [Managed Identity](https://learn.microsoft.com/azure/active-directory/managed-identities-azure-resources/overview), [Key Vault](https://learn.microsoft.com/azure/key-vault/general/overview),</br>[Private Link](https://learn.microsoft.com/azure/private-link/private-link-overview) / [ Endpoints](https://learn.microsoft.com/azure/private-link/private-endpoint-overview), [Network Security Groups](https://learn.microsoft.com/azure/virtual-network/network-security-groups-overview), [NAT Gateway](https://learn.microsoft.com/azure/nat-gateway/nat-overview), [Bastion](https://learn.microsoft.com/azure/bastion/bastion-overview), [Defender for Cloud](https://learn.microsoft.com/azure/defender-for-cloud/defender-for-cloud-introduction), [Policy](https://learn.microsoft.com/azure/governance/policy/overview), etc
* Any custom software or 3rd-party software is supported in a [Compute Gallery](https://learn.microsoft.com/azure/virtual-machines/shared-image-galleries) custom image repository
* Both Multi-Region and Edge Zone deployments are supported via a [Virtual Network](https://learn.microsoft.com/azure/virtual-network/virtual-networks-overview) per region / zone
* Clean separation of [Terraform](https://www.terraform.io) configuration files (config.\*.auto.tfvars) and implementation files (\*.tf)

| **Module Name** | **Module Description** | **Required for<br/>Burst Render?<br/>(*Compute Only*)** | **Required for<br/>Full Solution?<br/>(*Compute & Storage*)** |
| - | - | - | - |
| [0&#160;Global&#160;Foundation](https://github.com/Azure/ArtistAnywhere/tree/main/0.Global.Foundation) | Defines&#160;global&#160;config&#160;([Azure&#160;Region](https://azure.microsoft.com/regions)) and core services ([Terraform Storage](https://developer.hashicorp.com/terraform/language/settings/backends/azurerm), [Managed Identity](https://learn.microsoft.com/azure/active-directory/managed-identities-azure-resources/overview), [AI Services](https://learn.microsoft.com/azure/ai-services/what-are-ai-services), etc). | Yes ([AI Services](https://learn.microsoft.com/azure/ai-services/what-are-ai-services) are optional) | Yes ([AI Services](https://learn.microsoft.com/azure/ai-services/what-are-ai-services) are optional) |
| [1 Virtual Network](https://github.com/Azure/ArtistAnywhere/tree/main/1.Virtual.Network) | Deploys [Virtual Network](https://learn.microsoft.com/azure/virtual-network/virtual-networks-overview) with [VPN](https://learn.microsoft.com/azure/vpn-gateway/vpn-gateway-about-vpngateways)<br/>or [ExpressRoute](https://learn.microsoft.com/azure/expressroute/expressroute-about-virtual-network-gateways) gateway services. | Yes,&#160;if&#160;[Virtual&#160;Network](https://learn.microsoft.com/azure/virtual-network/virtual-networks-overview) is not yet deployed | Yes,&#160;if&#160;[Virtual&#160;Network](https://learn.microsoft.com/azure/virtual-network/virtual-networks-overview) is not yet deployed |
| [2 Image Builder](https://github.com/Azure/ArtistAnywhere/tree/main/2.Image.Builder) | Deploys [Image Builder](https://learn.microsoft.com/azure/virtual-machines/image-builder-overview) and [Compute Gallery](https://learn.microsoft.com/azure/virtual-machines/shared-image-galleries) with image customize scripts. | No, use your custom image config [here](https://github.com/Azure/ArtistAnywhere/tree/main/6.Render.Farm/config.auto.tfvars#L15) | No, use your custom image config [here](https://github.com/Azure/ArtistAnywhere/tree/main/6.Render.Farm/config.auto.tfvars#L15) |
| [3 File Storage](https://github.com/Azure/ArtistAnywhere/tree/main/3.File.Storage) | Deploys native ([Blob [NFS]](https://learn.microsoft.com/azure/storage/blobs/network-file-system-protocol-support), [Files](https://learn.microsoft.com/azure/storage/files/storage-files-introduction), [NetApp Files](https://learn.microsoft.com/azure/azure-netapp-files/azure-netapp-files-introduction), [Qumulo](https://learn.microsoft.com/azure/partner-solutions/qumulo/qumulo-overview), [Lustre](https://learn.microsoft.com/azure/azure-managed-lustre/amlfs-overview)) or hosted ([Weka](https://azuremarketplace.microsoft.com/marketplace/apps/weka1652213882079.weka_data_platform)) storage services. | No | Yes |
| [4 File Cache](https://github.com/Azure/ArtistAnywhere/tree/main/4.File.Cache) | Deploys [Hammerspace](https://azuremarketplace.microsoft.com/marketplace/apps/hammerspace.hammerspace-byol), [HPC Cache](https://learn.microsoft.com/azure/hpc-cache/hpc-cache-overview)<br/>or [Avere vFXT](https://learn.microsoft.com/azure/avere-vfxt/avere-vfxt-overview) file cache services. | Yes | No |
| [5 Render Manager](https://github.com/Azure/ArtistAnywhere/tree/main/5.Render.Manager) | Deploys [Virtual Machines](https://learn.microsoft.com/azure/virtual-machines) for render job scheduling and management. | No | No |
| [6 Render Farm](https://github.com/Azure/ArtistAnywhere/tree/main/6.Render.Farm) | Deploys [Compute Fleet](https://learn.microsoft.com/azure/azure-compute-fleet/overview) or [VM Scale Sets](https://learn.microsoft.com/azure/virtual-machine-scale-sets/overview) for scalable render compute. | Yes | Yes |
| [7&#160;Artist&#160;Workstation](https://github.com/Azure/ArtistAnywhere/tree/main/7.Artist.Workstation) | Deploys [Virtual Machines](https://learn.microsoft.com/azure/virtual-machines/overview) for remote artist workstations with [HP Anyware](https://www.teradici.com). | No | No |

## Local Installation Process

The following installation process is required for local deployment orchestration.

1. Make sure the [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) is installed locally and accessible in your PATH environment variable.
1. Make sure the [Terraform CLI](https://developer.hashicorp.com/terraform/downloads) is installed locally and accessible in your PATH environment variable.
1. Run `az login` locally to authenticate to your Azure account. This is how Terraform connects to Azure.
1. Run `az account show` to confirm your current Azure *subscription* context is set as expected locally.<br/>To change your current Azure subscription context, run `az account set --subscription <subscriptionId>`
1. Clone this GitHub repo to your local workstation for module configuration and deployment orchestration.

## Module Configuration & Deployment

For each module, here is the recommended configuration and deployment process.

1. Review and edit the config values in `config.\*.auto.tfvars` as needed for your target deployment.
   * For module `0 Global Foundation`, review and edit the following config files.
      * `module/backend.config`
      * `module/variables.tf`
   * For modules `2 Image Builder`, `5 Render Manager` and `7 Artist Workstation`, make sure you have sufficient **Standard** compute cores quota available on your Azure subscription for each configured virtual machine type / size.
   * For module `6 Render Farm`, make sure you have sufficient [Spot](https://learn.microsoft.com/azure/virtual-machines/spot-vms) compute cores quota available on your Azure subscription for each configured virtual machine type / size.
   * For modules `5 Render Manager`, `6 Render Farm` and `7 Artist Workstation`, make sure each **image** config references the correct [Compute Gallery](https://learn.microsoft.com/azure/virtual-machines/shared-image-galleries) custom image in your Azure subscription.
1. For module `0 Global Foundation`, run `terraform init` to initialize the module local directory (append `-upgrade` if older providers are detected).
1. For all modules except `0 Global Foundation`, run `terraform init -backend-config ../0.Global.Foundation/config/backend.config` to initialize the module local directory (append `-upgrade` if older providers are detected).
1. Run `terraform apply` to generate the Terraform deployment [Plan](https://www.terraform.io/docs/cli/run/index.html#planning) (append `-destroy` to delete Azure resources).
1. Review the Terraform deployment Plan *before* confirming to add, change and/or destroy Azure resources.
   * For module `2 Image Builder` to build virtual machine images, use the Azure portal or [Image Builder CLI](https://learn.microsoft.com/cli/azure/image/builder#az-image-builder-run) to start image build runs as needed.

## Render Job Samples

The following sample images were rendered on Azure via multiple render farm, engine and job submission options.

### [Disney Moana Island](https://www.disneyanimation.com/resources/moana-island-scene)

The following Disney Moana Island scene was rendered on Azure via the [Physically-Based Ray Tracer (PBRT) v4](https://github.com/mmp/pbrt-v4) render engine.

![moana-island](https://github.com/Azure/ArtistAnywhere/assets/22285652/7320acaf-061d-40a5-95e8-3a157a0a513c)

To render the Disney Moana Island scene on an Azure **Linux** render farm, the following job submission command can be submitted from a **Linux** and/or **Windows** artist workstation.

```deadlinecommand -SubmitCommandLineJob -name moana-island -executable pbrt -arguments "--outfile /mnt/content/pbrt/moana/island-v4.png /mnt/content/pbrt/moana/island/pbrt-v4/island.pbrt"```

To render the Disney Moana Island scene on an Azure **Windows** render farm, the following job submission command can be submitted from a **Linux** and/or **Windows** artist workstation.

```deadlinecommand -SubmitCommandLineJob -name moana-island -executable pbrt.exe -arguments "--outfile X:\pbrt\moana\island-v4.png X:\pbrt\moana\island\pbrt-v4\island.pbrt"```

### [Blender Splash Screen](https://www.blender.org/download/demo-files/#splash)

The following Blender 3.4 Splash screen was rendered on Azure via the [Blender](https://www.blender.org) render engine.

![blender-splash-3 4](https://github.com/Azure/ArtistAnywhere/assets/22285652/07576415-ba75-454f-90b6-04f20cfecbe2)

To render the Blender Splash screen on an Azure **Linux** render farm, the following job submission command can be submitted from a **Linux** and/or **Windows** artist workstation.

```deadlinecommand -SubmitCommandLineJob -name blender-splash -executable blender -arguments "--background /mnt/content/blender/3.4/splash.blend --render-output /mnt/content/blender/3.4/splash --enable-autoexec --render-frame 1"```

To render the Blender Splash screen on an Azure **Windows** render farm, the following job submission command can be submitted from a **Linux** and/or **Windows** artist workstation.

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
