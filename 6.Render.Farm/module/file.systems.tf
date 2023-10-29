variable fileSystems {
  default = {
    linux = [
      {
        enable   = false # File Storage
        iaasOnly = false
        mount = {
          type    = "aznfs"
          path    = "content"
          source  = "xstudio1.blob.core.windows.net:/xstudio1/content"
          options = "default,sec=sys,proto=tcp,vers=3,nolock"
        }
      },
      {
        enable   = false # File Cache
        iaasOnly = false
        mount = {
          type    = "nfs"
          path    = "content"
          source  = "cache.artist.studio:/content"
          options = "hard,proto=tcp,mountproto=tcp,retry=30,nolock"
        }
      },
      {
        enable   = true # Job Scheduler
        iaasOnly = true
        mount = {
          type    = "nfs"
          path    = "deadline"
          source  = "scheduler.artist.studio:/deadline"
          options = "defaults"
        }
      }
    ]
    windows = [
      {
        enable   = false # File Storage
        iaasOnly = true
        mount = {
          type    = ""
          path    = "X:"
          source  = "\\\\xstudio1.blob.core.windows.net\\xstudio1\\content"
          options = "-o anon nolock"
          userName = ""
          password = ""
        }
      },
      {
        enable   = false # File Cache
        iaasOnly = true
        mount = {
          type    = ""
          path    = "X:"
          source  = "\\\\cache.artist.studio\\content"
          options = "-o anon nolock"
          userName = ""
          password = ""
        }
      },
      {
        enable   = true # Job Scheduler
        iaasOnly = true
        mount = {
          type     = ""
          path     = "S:"
          source   = "\\\\scheduler.artist.studio\\deadline"
          options  = "-o anon"
          userName = ""
          password = ""
        }
      }
    ]
  }
}

output fileSystems {
  value = var.fileSystems
}
