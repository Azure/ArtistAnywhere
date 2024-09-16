variable fileSystems {
  default = [
    { # Blob Storage (NFS v3)
      enable = false
      linux = [
        { # File Storage
          enable = false
          mount = {
            type    = "aznfs"
            path    = "/mnt/storage"
            source  = "xstudio1.blob.core.windows.net:/xstudio1/storage"
            options = "sec=sys,proto=tcp,vers=3,nolock"
          }
        },
        { # File Cache
          enable = false
          mount = {
            type    = "aznfs"
            path    = "/mnt/storage"
            source  = "cache.azure.studio:/storage"
            options = "defaults"
          }
        },
        { # Job Manager
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
            source  = "\\\\xstudio1.blob.core.windows.net\\xstudio1\\storage"
            options = "-o anon nolock"
            userName = ""
            password = ""
          }
        },
        { # File Cache
          enable = false
          mount = {
            type    = ""
            path    = "X:"
            source  = "\\\\cache.azure.studio\\storage"
            options = "-o anon nolock"
            userName = ""
            password = ""
          }
        },
        { # Job Manager
          enable = true
          mount = {
            type     = ""
            path     = "S:"
            source   = "\\\\job.azure.studio\\deadline"
            options  = "-o anon"
            userName = ""
            password = ""
          }
        }
      ]
    },
    { # NetApp Files (NFS v3)
      enable = false
      linux = [
        { # File Storage
          enable = false
          mount = {
            type    = "nfs"
            path    = "/mnt/storage"
            source  = "netapp-volume1.azure.studio:/volume1"
            options = "hard,tcp,vers=3"
          }
        },
        { # File Cache
          enable = false
          mount = {
            type    = "nfs"
            path    = "/mnt/storage"
            source  = "cache.azure.studio:/storage"
            options = "hard,proto=tcp,mountproto=tcp,retry=30,nolock"
          }
        },
        { # Job Manager
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
            source  = "\\\\netapp-volume1.azure.studio\\volume1"
            options = "-o anon nolock"
            userName = ""
            password = ""
          }
        },
        { # File Cache
          enable = false
          mount = {
            type    = ""
            path    = "X:"
            source  = "\\\\cache.azure.studio\\storage"
            options = "-o anon nolock"
            userName = ""
            password = ""
          }
        },
        { # Job Manager
          enable = true
          mount = {
            type     = ""
            path     = "S:"
            source   = "\\\\job.azure.studio\\deadline"
            options  = "-o anon"
            userName = ""
            password = ""
          }
        }
      ]
    }
  ]
}

output fileSystems {
  value = var.fileSystems
}
