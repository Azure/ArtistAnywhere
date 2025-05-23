resourceGroupName = "AAA.Cache"

#################################################################################################################
# Boost              (https://learn.microsoft.com/azure/azure-boost/overview)                                   #
# Managed Grafana    (https://learn.microsoft.com/azure/managed-grafana/overview)                               #
# Monitor Prometheus (https://learn.microsoft.com/azure/azure-monitor/metrics/prometheus-metrics-overview)      #
# Monitor Workspace  (https://learn.microsoft.com/azure/azure-monitor/metrics/azure-monitor-workspace-overview) #
#################################################################################################################

nfsCache = {
  enable = false
  name   = "xcache"
  machine = {
    size   = "Standard_L80as_v3" # https://learn.microsoft.com/azure/virtual-machines/sizes
    count  = 1
    prefix = ""
    image = {
      publisher = ""
      product   = ""
      name      = ""
      version   = ""
    }
    osDisk = {
      storageType = "Premium_LRS"
      cachingMode = "ReadOnly"
      sizeGB      = 0
      ephemeral = { # https://learn.microsoft.com/azure/virtual-machines/ephemeral-os-disks
        enable    = true
        placement = "ResourceDisk"
      }
    }
    dataDisk = {
      enable      = false
      storageType = "UltraSSD_LRS"
      cachingMode = "None"
      sizeGB      = 65536
      count       = 1
    }
    adminLogin = {
      userName     = ""
      userPassword = ""
      sshKeyPublic = ""
      passwordAuth = {
        disable = true
      }
    }
    extension = {
      custom = {
        enable   = true
        name     = "Custom"
        fileName = "nfs.sh"
        parameters = {
          storageMounts = [
            {
              enable      = true
              type        = "nfs"
              path        = "/storage"
              source      = "storage-netapp.azure.hpc:/data"
              options     = "fsc,rw,tcp,vers=3,nconnect=8"
              description = "Remote NFSv3 Storage"
              permissions = {
                enable     = false
                recursive  = false
                octalValue = 777
              }
            }
          ]
          cacheMetrics = {
            intervalSeconds = 15
            nodeExportsPort = 9100
            customStatsPort = 9110
          }
        }
      }
    }
  }
  network = {
    acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
      enable = true
    }
  }
}

############################################################################
# Private DNS (https://learn.microsoft.com/azure/dns/private-dns-overview) #
############################################################################

dnsRecord = {
  name       = "cache"
  ttlSeconds = 300
}

########################
# Brownfield Resources #
########################

monitorWorkspace = {
  name              = "hpcai"
  resourceGroupName = "AAA.Monitor"
  metricsIngestion = {
    apiVersion = "2023-04-24"
  }
}

managedGrafana = {
  name              = "hpcai"
  resourceGroupName = "AAA.Monitor"
}

virtualNetwork = {
  name              = "HPC"
  subnetName        = "Cache"
  resourceGroupName = "AAA.Network.SouthCentralUS"
  privateDNS = {
    zoneName          = "azure.hpc"
    resourceGroupName = "AAA.Network"
  }
}

activeDirectory = {
  enable = false
  domain = {
    name = "azure.hpc"
  }
  machine = {
    name = "WinADController"
    adminLogin = {
      userName     = ""
      userPassword = ""
    }
  }
}
