# Azure Artist Anywhere (AAA) Deployment Framework

Azure Artist Anywhere (AAA) is a *modular & flexible* [Infrastructure as Code (IaC)](https://learn.microsoft.com/devops/deliver/what-is-infrastructure-as-code) solution deployment framework for<br/>[Azure HPC](https://azure.microsoft.com/solutions/high-performance-computing) & [Azure AI Infrastructure (GPU)](https://azure.microsoft.com/solutions/high-performance-computing/ai-infrastructure) workloads. Enable remote user productivity with [global Azure scale](https://azure.microsoft.com/global-infrastructure) via AI-</br>enabled [Compute Fleet](https://learn.microsoft.com/azure/azure-compute-fleet/overview) deployments with up to 10,000 [Spot VMs](https://learn.microsoft.com/azure/virtual-machines/spot-vms) / [Standard VMs](https://learn.microsoft.com/azure/virtual-machines/overview) and up to 15 [VM sizes](https://learn.microsoft.com/azure/virtual-machines/sizes/overview) per request.

The following solution design principles and features are implemented throughout the AAA deployment framework.
* Defense-in-depth layered security with integration of core services including [Managed Identity](https://learn.microsoft.com/entra/identity/managed-identities-azure-resources/overview), [Key Vault](https://learn.microsoft.com/azure/key-vault/general/overview),</br>[Private Link](https://learn.microsoft.com/azure/private-link/private-link-overview) / [ Endpoints](https://learn.microsoft.com/azure/private-link/private-endpoint-overview), [Network Security Groups](https://learn.microsoft.com/azure/virtual-network/network-security-groups-overview), [NAT Gateway](https://learn.microsoft.com/azure/nat-gateway/nat-overview), [Firewall](https://learn.microsoft.com/azure/firewall/overview), [Bastion](https://learn.microsoft.com/azure/bastion/bastion-overview), [Defender for Cloud](https://learn.microsoft.com/azure/defender-for-cloud/defender-for-cloud-introduction), etc
* Any 3<sup>rd</sup>-party or custom software (e.g., job manager) is supported in a custom image [Compute Gallery](https://learn.microsoft.com/azure/virtual-machines/shared-image-galleries)
* Multi-Region and [Extended Zone](https://learn.microsoft.com/azure/extended-zones/overview) deployments are supported via a [Virtual Network](https://learn.microsoft.com/azure/virtual-network/virtual-networks-overview) per region / zone
* Clean separation of [Terraform](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs) configuration files (**config.auto.tfvars**) and implementation files (**\*.tf**)

| **Module Name** | **Module Description** | **Required for<br/>Burst Compute?** | **Required for<br/>Full Solution?<br/>(*Compute & Storage*)** |
| - | - | - | - |
| [0 Foundation](https://github.com/Azure/ArtistAnywhere/tree/main/0.Foundation) | Defines&#160;core&#160;config&#160;([Azure&#160;Region](https://azure.microsoft.com/regions)) and resources ([Terraform Storage](https://developer.hashicorp.com/terraform/language/settings/backends/azurerm), [Managed Identity](https://learn.microsoft.com/entra/identity/managed-identities-azure-resources/overview), [Key Vault](https://learn.microsoft.com/azure/key-vault/general/overview), etc) | Yes | Yes |
| [1 Network](https://github.com/Azure/ArtistAnywhere/tree/main/1.Network) | Deploys [Virtual Network](https://learn.microsoft.com/azure/virtual-network/virtual-networks-overview) with [Virtual WAN](https://learn.microsoft.com/azure/virtual-wan/virtual-wan-about) and/or [VPN Gateway](https://learn.microsoft.com/azure/vpn-gateway/vpn-gateway-about-vpngateways) services | Yes,&#160;if&#160;[Virtual&#160;Network](https://learn.microsoft.com/azure/virtual-network/virtual-networks-overview) is not yet deployed | Yes,&#160;if&#160;[Virtual&#160;Network](https://learn.microsoft.com/azure/virtual-network/virtual-networks-overview) is not yet deployed |
| [2 Image](https://github.com/Azure/ArtistAnywhere/tree/main/2.Image) | Deploys [Image Builder](https://learn.microsoft.com/azure/virtual-machines/image-builder-overview) and [Compute Gallery](https://learn.microsoft.com/azure/virtual-machines/shared-image-galleries) for x86_64 or ARM64 images | No, use your custom image config [here](https://github.com/Azure/ArtistAnywhere/tree/main/6.Compute.Cluster/config.auto.tfvars#L15) | No, use your custom image config [here](https://github.com/Azure/ArtistAnywhere/tree/main/6.Compute.Cluster/config.auto.tfvars#L15) |
| [3 File Storage](https://github.com/Azure/ArtistAnywhere/tree/main/3.File.Storage) | Deploys [Blob (NFS)](https://learn.microsoft.com/azure/storage/blobs/network-file-system-protocol-support), [Files](https://learn.microsoft.com/azure/storage/files/storage-files-introduction), [NetApp Files](https://learn.microsoft.com/azure/azure-netapp-files/azure-netapp-files-introduction), [Hammerspace](https://azuremarketplace.microsoft.com/marketplace/apps/hammerspace.hammerspace-byol) and/or [Lustre](https://learn.microsoft.com/azure/azure-managed-lustre/amlfs-overview) | No, use your current NAS via [4 File Cache](https://github.com/Azure/ArtistAnywhere/tree/main/4.File.Cache) | Yes |
| [4 File Cache](https://github.com/Azure/ArtistAnywhere/tree/main/4.File.Cache) | Deploys [Linux Kernel NFS](https://www.kernel.org/doc/Documentation/filesystems/caching/fscache.txt) caching or [Hammerspace](https://azuremarketplace.microsoft.com/marketplace/apps/hammerspace.hammerspace-byol) caching services | Yes | No |
| [5 Job Manager](https://github.com/Azure/ArtistAnywhere/tree/main/5.Job.Manager) | Deploys job manager [Virtual Machines](https://learn.microsoft.com/azure/virtual-machines) or [CycleCloud Workspace for Slurm](https://learn.microsoft.com/azure/cyclecloud/overview-ccws) | No | No |
| [6&#160;Job&#160;Cluster](https://github.com/Azure/ArtistAnywhere/tree/main/6.Job.Cluster) | Deploys [Compute Fleet](https://learn.microsoft.com/azure/azure-compute-fleet/overview) or [VM Scale Sets](https://learn.microsoft.com/azure/virtual-machine-scale-sets/overview) for scalable job clusters | Yes | Yes |
| [7 VDI](https://github.com/Azure/ArtistAnywhere/tree/main/7.VDI) | Deploys [Virtual Machines](https://learn.microsoft.com/azure/virtual-machines/overview) for remote user workstations with [HP Anyware](https://www.teradici.com/products/hp-anyware) | No | No |

## Render Job Samples

The following sample images were rendered on Azure using scalable clusters with HPC CPU and GPU infrastructure.

### [Disney Moana Island](https://www.disneyanimation.com/resources/moana-island-scene)

The following Disney Moana Island scene was rendered on Azure via the [Physically-Based Ray Tracer (PBRT)](https://github.com/mmp/pbrt-v4) renderer.

![moana-island](https://github.com/Azure/ArtistAnywhere/assets/22285652/7320acaf-061d-40a5-95e8-3a157a0a513c)

To render the Disney Moana Island scene on an Azure **Linux** render cluster, the following job submission command can be submitted from a **Linux** or **Windows** user workstation.

```deadlinecommand -SubmitCommandLineJob -name moana-island -executable pbrt -arguments "--outfile /mnt/cache/cpu/moana-island.png /mnt/cache/cpu/island/pbrt-v4/island.pbrt"```

To render the Disney Moana Island scene on an Azure **Windows** render cluster, the following job submission command can be submitted from a **Linux** or **Windows** user workstation.

```deadlinecommand -SubmitCommandLineJob -name moana-island -executable pbrt.exe -arguments "--outfile Y:\cpu\moana-island.png Y:\cpu\island\pbrt-v4\island.pbrt"```

### [Blender Splash Screen](https://www.blender.org/download/demo-files/#splash)

The following Blender 3.4 Splash screen was rendered on Azure via the [Blender](https://www.blender.org) renderer.

![blender-splash](https://github.com/Azure/ArtistAnywhere/assets/22285652/07576415-ba75-454f-90b6-04f20cfecbe2)

To render the Blender Splash screen on an Azure **Linux** render cluster, the following job submission command can be submitted from a **Linux** or **Windows** user workstation.

```deadlinecommand -SubmitCommandLineJob -name blender-splash -executable blender -arguments "--background /mnt/cache/gpu/3.4/splash.blend --render-output /mnt/cache/gpu/3.4/splash --enable-autoexec --render-frame 1"```

To render the Blender Splash screen on an Azure **Windows** render cluster, the following job submission command can be submitted from a **Linux** or **Windows** user workstation.

```deadlinecommand -SubmitCommandLineJob -name blender-splash -executable blender.exe -arguments "--background Y:\gpu\3.4\splash.blend --render-output Y:\gpu\3.4\splash --enable-autoexec --render-frame 1"```

## Local Installation Process

The following local installation process is required for deployment orchestration.

1. Make sure the [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) is installed locally and accessible in your PATH environment variable.
1. Make sure the [Terraform CLI](https://developer.hashicorp.com/terraform/downloads) is installed locally and accessible in your PATH environment variable.
1. Clone this GitHub repository to your local workstation for module configuration and deployment.

## Module Configuration & Deployment

The following table highlights the configuration settings of each AAA module, including the required Terraform commands (`terraform init` and `terraform apply`).

| **Module Name** | **Module Configuration** |
| - | - |
| [0 Foundation](https://github.com/Azure/ArtistAnywhere/tree/main/0.Foundation) | 1. Ensure the current user has the required [Key Vault Administrator](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/security#key-vault-administrator) RBAC role assignment.<br/>2. Review and edit the default `config.auto.tfvars` file settings (Azure `subscriptionId`, `defaultLocation`, etc.) as needed for your target Azure deployment.<br/>3. Review and edit the following additional configuration files.<br/>&nbsp;&nbsp;&nbsp;&nbsp;* `/config/backend` - defines the required Azure Blob Storage resource names for Terraform backend state management<br/>&nbsp;&nbsp;&nbsp;&nbsp;* `/config/file.system.tf` - sets the shared file system for modules `6.Job.Cluster` and `7.VDI`<br/>4. Run `terraform init` in your local directory command shell (append `-upgrade` as needed if older Terraform providers are detected in your local directory).<br/>5. Run `terraform apply` in your local directory command shell to generate the Terraform deployment [Plan](https://www.terraform.io/docs/cli/run/index.html#planning) (append `-destroy` to generate an Azure resource delete plan).<br/>**6. *Before confirming apply*, carefully review the displayed Terraform deployment Plan.**
| [1 Network](https://github.com/Azure/ArtistAnywhere/tree/main/1.Network) | 1. Review and edit the default `config.auto.tfvars` file settings as needed for your target Azure deployment.<br/>2. Run `terraform init -backend-config ../0.Foundation/config/backend` in your local directory command shell (append `-upgrade` as needed).<br/>3. Run `terraform apply` in your local directory command shell to generate the Terraform deployment [Plan](https://www.terraform.io/docs/cli/run/index.html#planning) (append `-destroy` to generate an Azure resource delete plan).<br/>**4. *Before confirming apply*, carefully review the displayed Terraform deployment Plan.**
| [2 Image](https://github.com/Azure/ArtistAnywhere/tree/main/2.Image) | 1. Review and edit the default `config.auto.tfvars` file settings as needed for your target Azure deployment.<br/>2. Ensure you have sufficient **Standard** compute cores quota approved on your Azure subscription for each configured VM type / size in your target region.<br/>3. Run `terraform init -backend-config ../0.Foundation/config/backend` in your local directory command shell (append `-upgrade` as needed).<br/>4. Run `terraform apply` in your local directory command shell to generate the Terraform deployment [Plan](https://www.terraform.io/docs/cli/run/index.html#planning) (append `-destroy` to generate an Azure resource delete plan).<br/>**5. *Before confirming apply*, carefully review the displayed Terraform deployment Plan.**<br/>5. Use the Azure portal or [Image Builder CLI](https://learn.microsoft.com/cli/azure/image/builder#az-image-builder-run) to start **Image Template** build runs.
| [3 File Storage](https://github.com/Azure/ArtistAnywhere/tree/main/3.File.Storage) | 1. Review and edit the default `config.auto.tfvars` file settings as needed for your target Azure deployment.<br/>2. Run `terraform init -backend-config ../0.Foundation/config/backend` in your local directory command shell (append `-upgrade` as needed).<br/>3. Run `terraform apply` in your local directory command shell to generate the Terraform deployment [Plan](https://www.terraform.io/docs/cli/run/index.html#planning) (append `-destroy` to generate an Azure resource delete plan).<br/>**4. *Before confirming apply*, carefully review the displayed Terraform deployment Plan.**
| [4 File Cache](https://github.com/Azure/ArtistAnywhere/tree/main/4.File.Cache) | 1. Review and edit the default `config.auto.tfvars` file settings as needed for your target Azure deployment.<br/>2. Run `terraform init -backend-config ../0.Foundation/config/backend` in your local directory command shell (append `-upgrade` as needed).<br/>3. Run `terraform apply` in your local directory command shell to generate the Terraform deployment [Plan](https://www.terraform.io/docs/cli/run/index.html#planning) (append `-destroy` to generate an Azure resource delete plan).<br/>**4. *Before confirming apply*, carefully review the displayed Terraform deployment Plan.**
| [5 Job Manager](https://github.com/Azure/ArtistAnywhere/tree/main/5.Job.Manager) | 1. Review and edit the default `config.auto.tfvars` file settings as needed for your target Azure deployment.<br/>2. Ensure you have sufficient **Standard** compute cores quota approved on your Azure subscription for each configured VM type / size in your target region.<br/>3. Ensure each **image** reference in `config.auto.tfvars` points to your [Compute Gallery](https://learn.microsoft.com/azure/virtual-machines/shared-image-galleries).<br/>4. Run `terraform init -backend-config ../0.Foundation/config/backend` in your local directory command shell (append `-upgrade` as needed).<br/>5. Run `terraform apply` in your local directory command shell to generate the Terraform deployment [Plan](https://www.terraform.io/docs/cli/run/index.html#planning) (append `-destroy` to generate an Azure resource delete plan).<br/>**6. *Before confirming apply*, carefully review the displayed Terraform deployment Plan.**
| [6&#160;Job&#160;Cluster](https://github.com/Azure/ArtistAnywhere/tree/main/6.Job.Cluster) | 1. Review and edit the default `config.auto.tfvars` file settings as needed for your target Azure deployment.<br/>2. Ensure you have sufficient **Standard** and/or [Spot](https://learn.microsoft.com/azure/virtual-machines/spot-vms) compute cores quota approved on your Azure subscription for each configured VM type / size in your target region.<br/>3. Ensure each **image** reference in `config.auto.tfvars` points to your [Compute Gallery](https://learn.microsoft.com/azure/virtual-machines/shared-image-galleries).<br/>4. Run `terraform init -backend-config ../0.Foundation/config/backend` in your local directory command shell (append `-upgrade` as needed).<br/>5. Run `terraform apply` in your local directory command shell to generate the Terraform deployment [Plan](https://www.terraform.io/docs/cli/run/index.html#planning) (append `-destroy` to generate an Azure resource delete plan).<br/>**6. *Before confirming apply*, carefully review the displayed Terraform deployment Plan.**
| [7 VDI](https://github.com/Azure/ArtistAnywhere/tree/main/7.VDI) | 1. Review and edit the default `config.auto.tfvars` file settings as needed for your target Azure deployment.<br/>2. Ensure you have sufficient **Standard** compute cores quota approved on your Azure subscription for each configured VM type / size in your target region.<br/>3. Ensure each **image** reference in `config.auto.tfvars` points to your [Compute Gallery](https://learn.microsoft.com/azure/virtual-machines/shared-image-galleries).<br/>4. Run `terraform init -backend-config ../0.Foundation/config/backend` in your local directory command shell (append `-upgrade` as needed).<br/>5. Run `terraform apply` in your local directory command shell to generate the Terraform deployment [Plan](https://www.terraform.io/docs/cli/run/index.html#planning) (append `-destroy` to generate an Azure resource delete plan).<br/>**6. *Before confirming apply*, carefully review the displayed Terraform deployment Plan.**

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
