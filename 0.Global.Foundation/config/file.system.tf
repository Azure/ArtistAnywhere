variable fileSystem {
  default = {
    linux = [
      { # File Storage
        enable = false
        mount = {
          type    = "nfs"
          path    = "/mnt/storage"
          target  = "storage-data.azure.studio:/data"
          options = "vers=3"
        }
      },
      { # File Cache (NFS)
        enable = false
        mount = {
          type    = "nfs"
          path    = "/mnt/cache"
          target  = "cache.azure.studio:/mnt/storage"
          options = "vers=3,ro"
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
      },
      { # Job Scheduler
        enable = true
        mount = {
          type    = "nfs"
          path    = "/mnt/deadline"
          target  = "job.azure.studio:/deadline"
          options = "defaults"
        }
      }
    ]
    windows = [
      { # File Storage
        enable = false
        mount = {
          type    = ""
          path    = "X:"
          target  = "\\\\storage-data.azure.studio\\data"
          options = "-o anon"
        }
      },
      { # File Cache
        enable = false
        mount = {
          type    = ""
          path    = "Y:"
          target  = "\\\\cache.azure.studio\\mnt\\storage"
          options = "-o anon"
        }
      },
      { # Job Scheduler
        enable = true
        mount = {
          type    = ""
          path    = "S:"
          target  = "\\\\job.azure.studio\\deadline"
          options = "-o anon"
        }
      }
    ]
  }
}

output fileSystem {
  value = var.fileSystem
}
