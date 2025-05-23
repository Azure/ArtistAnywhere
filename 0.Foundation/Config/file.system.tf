variable fileSystem {
  default = {
    linux = [
      { # Job Manager
        enable = true
        mount = {
          type    = "nfs"
          path    = "/mnt/deadline"
          target  = "job.azure.hpc:/deadline"
          options = "defaults"
        }
      },
      { # File Storage (NFS v3)
        enable = false
        mount = {
          type    = "nfs"
          path    = "/mnt/storage"
          target  = "storage-netapp.azure.hpc:/data"
          options = "rw,nconnect=8,vers=3"
        }
      },
      { # File Cache (NFS v4.x)
        enable = false
        mount = {
          type    = "nfs"
          path    = "/mnt/cache"
          target  = "cache.azure.hpc:/storage"
          options = "rw,nconnect=8"
        }
      },
      { # File Cache (Lustre)
        enable = false
        mount = {
          type    = "lustre"
          path    = "/mnt/cache"
          target  = "cache.azure.hpc@tcp:/lustrefs"
          options = "noatime,flock,_netdev,x-systemd.automount,x-systemd.requires=network.service"
        }
      }
    ]
    windows = [
      { # Job Manager
        enable = true
        mount = {
          type    = ""
          path    = "S:"
          target  = "\\\\job.azure.hpc\\deadline"
          options = "-o anon"
        }
      },
      { # File Storage
        enable = false
        mount = {
          type    = ""
          path    = "X:"
          target  = "\\\\storage-netapp.azure.hpc\\data"
          options = "-o anon -o nconnnect=8 -o vers=3"
        }
      },
      { # File Cache
        enable = false
        mount = {
          type    = ""
          path    = "Y:"
          target  = "\\\\cache.azure.hpc\\storage"
          options = "-o anon -o nconnnect=8"
        }
      }
    ]
  }
}

output fileSystem {
  value = var.fileSystem
}
