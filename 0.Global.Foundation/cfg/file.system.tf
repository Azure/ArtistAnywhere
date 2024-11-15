variable fileSystem {
  default = { # NetApp Files (ANF)
    enable = false
    linux = [
      { # File Storage
        enable = false
        mount = {
          type    = "nfs"
          path    = "/mnt/storage"
          source  = "anf-volume1.azure.studio:/volume1"
          options = "vers=3,hard,tcp"
        }
      },
      { # File Cache
        enable = false
        mount = {
          type    = "nfs"
          path    = "/mnt/cache"
          source  = "cache.azure.studio:/volume1"
          options = "defaults"
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
          source  = "\\\\anf-volume1.azure.studio\\volume1"
          options = "-o anon"
        }
      },
      { # File Cache
        enable = false
        mount = {
          type    = ""
          path    = "Y:"
          source  = "\\\\cache.azure.studio\\storage"
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
