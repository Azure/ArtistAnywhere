resourceGroupName = "AAA.Cache"

######################################################################################################
# Hammerspace (https://azuremarketplace.microsoft.com/marketplace/apps/hammerspace.hammerspace-byol) #
######################################################################################################

hammerspace = {
  enable     = false
  namePrefix = "hpcai"
  domainName = "azure.hpc"
  metadata = { # Anvil
    machine = {
      namePrefix = "-anvil"
      size       = "Standard_E8as_v5"
      count      = 1
      osDisk = {
        storageType = "Premium_LRS"
        cachingMode = "ReadWrite"
        sizeGB      = 128
      }
      dataDisk = {
        storageType = "Premium_LRS"
        cachingMode = "None"
        sizeGB      = 1024
      }
      adminLogin = {
        userName     = ""
        userPassword = ""
        sshKeyPublic = ""
        passwordAuth = {
          disable = true
        }
      }
    }
    network = {
      acceleration = {
        enable = true
      }
    }
  }
  data = { # DSX
    machine = {
      namePrefix = "-dsx"
      size       = "Standard_E32as_v5"
      count      = 2
      osDisk = {
        storageType = "Premium_LRS"
        cachingMode = "ReadWrite"
        sizeGB      = 128
      }
      dataDisk = {
        storageType = "Premium_LRS"
        cachingMode = "None"
        sizeGB      = 1024
        count       = 4
        raid0 = {
          enable = false
        }
      }
      adminLogin = {
        userName     = ""
        userPassword = ""
        sshKeyPublic = ""
        passwordAuth = {
          disable = true
        }
      }
    }
    network = {
      acceleration = {
        enable = true
      }
    }
  }
  proximityPlacementGroup = {
    enable = false
  }
  storageAccounts = [
    {
      enable    = false
      name      = ""
      accessKey = ""
    }
  ]
  shares = [
    {
      enable = true
      name   = "ReadOnly"
      path   = "/ro"
      size   = 0
      export = "*,ro,root-squash,insecure"
    },
    {
      enable = true
      name   = "ReadWrite"
      path   = "/rw"
      size   = 0
      export = "*,rw,root-squash,insecure"
    }
  ]
  volumes = [
    {
      enable = true
      name   = "data"
      type   = "READ_ONLY"
      path   = "/data"
      purge  = false
      node = {
        name    = "node1"
        type    = "OTHER"
        address = "10.1.194.4"
      }
      assimilation = {
        enable = true
        share = {
          name = "ReadOnly"
          path = {
            source      = "/"
            destination = "/data"
          }
        }
      }
    },
    {
      enable = true
      name   = "tools"
      type   = "READ_ONLY"
      path   = "/tools"
      purge  = false
      node = {
        name    = "node1"
        type    = "OTHER"
        address = "10.1.194.4"
      }
      assimilation = {
        enable = true
        share = {
          name = "ReadOnly"
          path = {
            source      = "/"
            destination = "/tools"
          }
        }
      }
    },
    {
      enable = true
      name   = "shared"
      type   = "READ_ONLY"
      path   = "/shared"
      purge  = false
      node = {
        name    = "node1"
        type    = "OTHER"
        address = "10.1.194.4"
      }
      assimilation = {
        enable = true
        share = {
          name = "ReadOnly"
          path = {
            source      = "/"
            destination = "/shared"
          }
        }
      }
    },
    {
      enable = true
      name   = "scratch"
      type   = "READ_WRITE"
      path   = "/scratch"
      purge  = true
      node = {
        name    = "node1"
        type    = "OTHER"
        address = "10.1.194.4"
      }
      assimilation = {
        enable = true
        share = {
          name = "ReadWrite"
          path = {
            source      = "/"
            destination = "/scratch"
          }
        }
      }
    }
  ]
  volumeGroups = [
    {
      enable = true
      name   = "ReadOnly"
      volumeNames = [
        "data",
        "tools",
        "shared"
      ]
    },
    {
      enable = true
      name   = "ReadWrite"
      volumeNames = [
        "scratch"
      ]
    }
  ]
}

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
      publisher = "AlmaLinux"
      product   = "AlmaLinux-x86_64"
      name      = "9-Gen2"
      version   = "9.5.202411260"
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
    name = "WinAD"
    adminLogin = {
      userName     = ""
      userPassword = ""
    }
  }
}
