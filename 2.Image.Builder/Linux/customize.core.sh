#!/bin/bash -ex

source /tmp/functions.sh

echo "Customize (Start): Core"

echo "Customize (Start): Image Build Platform"
dnf -y install epel-release python3-devel gcc-c++ git cmake bzip2
export AZNFS_NONINTERACTIVE_INSTALL=1 AZNFS_FORCE_PACKAGE_MANAGER=dnf
curl -L https://github.com/Azure/AZNFS-mount/releases/latest/download/aznfs_install.sh | /bin/bash
if [ $machineType == Workstation ]; then
  echo "Customize (Start): Image Build Platform (Workstation)"
  dnf -y group install workstation
  echo "Customize (End): Image Build Platform (Workstation)"
fi
echo "Customize (End): Image Build Platform"

if [ $machineType == Scheduler ]; then
  echo "Customize (Start): Azure CLI"
  rpm --import https://packages.microsoft.com/keys/microsoft.asc
  dnf -y install https://packages.microsoft.com/config/rhel/9/packages-microsoft-prod.rpm
  dnf -y install azure-cli
  echo "Customize (End): Azure CLI"
fi

echo "Customize (Start): Azure Managed Lustre (AMLFS) Client"
rpm --import https://packages.microsoft.com/keys/microsoft.asc
repoName="amlfs"
repoPath="/etc/yum.repos.d/$repoName.repo"
echo "[$repoName]" > $repoPath
echo "name=Azure Lustre Packages" >> $repoPath
echo "baseurl=https://packages.microsoft.com/yumrepos/amlfs-el9" >> $repoPath
echo "enabled=1" >> $repoPath
echo "gpgcheck=1" >> $repoPath
echo "gpgkey=https://packages.microsoft.com/keys/microsoft.asc" >> $repoPath
dnf -y install amlfs-lustre-client-2.15.6_39_g3e00a10-$(uname -r | sed -e "s/\.$(uname -p)$//" | sed -re 's/[-_]/\./g')-1
echo "Customize (End): Azure Managed Lustre (AMLFS) Client"

if [ "$binPaths" != "" ]; then
  echo "Customize (PATH): ${binPaths:1}"
  echo 'PATH=$PATH'$binPaths >> $aaaProfile
fi

echo "Customize (End): Core"
