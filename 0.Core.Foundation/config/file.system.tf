variable fileSystem {
  default = {
    linux = [
      { # Job Scheduler
        enable = true
        mount = {
          type    = "nfs"
          path    = "/mnt/deadline"
          target  = "job.azure.studio:/deadline"
          options = "defaults"
        }
      },
      { # File Storage
        enable = false
        mount = {
          type    = "nfs"
          path    = "/mnt/storage"
          target  = "storage-data.azure.studio:/data"
          options = "rw,nconnect=8,vers=3"
        }
      },
      { # File Cache (NFS)
        enable = false
        mount = {
          type    = "nfs"
          path    = "/mnt/cache"
          target  = "cache.azure.studio:/mnt/storage"
          options = "ro,nconnect=8"
        }
      },
      { # File Cache (Lustre)
        enable = false
        mount = {
          type    = "lustre"
          path    = "/mnt/cache"
          target  = "cache.azure.studio@tcp:/lustrefs"
          options = "noatime,flock,_netdev,x-systemd.automount,x-systemd.requires=network.service"
        }
      }
    ]
    windows = [
      { # Job Scheduler
        enable = true
        mount = {
          type    = ""
          path    = "S:"
          target  = "\\\\job.azure.studio\\deadline"
          options = "-o anon"
        }
      },
      { # File Storage
        enable = false
        mount = {
          type    = ""
          path    = "X:"
          target  = "\\\\storage-data.azure.studio\\data"
          options = "-o anon -o nconnnect=8 -o vers=3"
        }
      },
      { # File Cache
        enable = false
        mount = {
          type    = ""
          path    = "Y:"
          target  = "\\\\cache.azure.studio\\mnt\\storage"
          options = "-o anon -o nconnnect=8"
        }
      }
    ]
  }
}

output fileSystem {
  value = var.fileSystem
}
