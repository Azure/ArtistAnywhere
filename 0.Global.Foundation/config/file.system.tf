variable fileSystem {
  default = {
    linux = [
      { # File Storage
        enable = false
        mount = {
          type    = "nfs"
          path    = "/mnt/storage"
          source  = "storage-data.azure.studio:/volume1"
          options = "vers=3"
        }
      },
      { # File Cache
        enable = false
        mount = {
          type    = "nfs"
          path    = "/mnt/cache"
          source  = "cache-data.azure.studio:/cache"
          options = "vers=3"
        }
      },
      { # Job Scheduler
        enable = true
        mount = {
          type    = "nfs"
          path    = "/mnt/deadline"
          source  = "job.azure.studio:/deadline"
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
          source  = "\\\\storage-data.azure.studio\\volume1"
          options = "-o anon"
        }
      },
      { # File Cache
        enable = false
        mount = {
          type    = ""
          path    = "Y:"
          source  = "\\\\cache-data.azure.studio\\cache"
          options = "-o anon"
        }
      },
      { # Job Scheduler
        enable = true
        mount = {
          type    = ""
          path    = "S:"
          source  = "\\\\job.azure.studio\\deadline"
          options = "-o anon"
        }
      }
    ]
  }
}

output fileSystem {
  value = var.fileSystem
}
