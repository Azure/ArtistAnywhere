variable fileSystems {
  default = {
    linux = [
      {
        enable   = false # File Storage
        iaasOnly = false
        mount = {
          type    = "aznfs"
          path    = "/mnt/content"
          source  = "xstudio1.blob.core.windows.net:/xstudio1/content"
          options = "default,sec=sys,proto=tcp,vers=3,nolock 0 0"
        }
      },
      {
        enable   = false # File Cache
        iaasOnly = false
        mount = {
          type    = "nfs"
          path    = "/mnt/content"
          source  = "cache.artist.studio:/content"
          options = "hard,proto=tcp,mountproto=tcp,retry=30,nolock 0 0"
        }
      },
      {
        enable   = true # Job Scheduler
        iaasOnly = true
        mount = {
          type    = "nfs"
          path    = "/mnt/deadline"
          source  = "scheduler.artist.studio:/deadline"
          options = "defaults 0 0"
        }
      }
    ]
    windows = [
      {
        enable   = false # File Storage
        iaasOnly = false
        mount = {
          type    = ""
          path    = "X:"
          source  = "\\\\xstudio1.blob.core.windows.net\\xstudio1\\content"
          options = "-o anon nolock"
        }
      },
      {
        enable   = false # File Cache
        iaasOnly = false
        mount = {
          type    = ""
          path    = "X:"
          source  = "\\\\cache.artist.studio\\content"
          options = "-o anon nolock"
        }
      },
      {
        enable   = true # Job Scheduler
        iaasOnly = true
        mount = {
          type    = ""
          path    = "S:"
          source  = "\\\\scheduler.artist.studio\\deadline"
          options = "-o anon"
        }
      }
    ]
  }
}

output fileSystems {
  value = var.fileSystems
}
