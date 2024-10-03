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
            options = "vers=3,sec=sys,proto=tcp,nolock"
          }
        },
        { # File Cache
          enable = false
          mount = {
            type    = "aznfs"
            path    = "/mnt/storage"
            source  = "cache.azure.studio:/storage"
            options = "vers=3,sec=sys,proto=tcp,nolock"
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
        { # Job Scheduler
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
    { # File Storage (NFS v4.1)
      enable = false
      linux = [
        { # File Storage
          enable = false
          mount = {
            type    = "aznfs"
            path    = "/mnt/storage"
            source  = "xstudio2.file.core.windows.net:/xstudio2/storage"
            options = "vers=4,minorversion=1,sec=sys,nconnect=4"
          }
        },
        { # File Cache
          enable = false
          mount = {
            type    = "aznfs"
            path    = "/mnt/storage"
            source  = "cache.azure.studio:/storage"
            options = "vers=4,minorversion=1,sec=sys,nconnect=4"
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
            source  = "\\\\xstudio2.file.core.windows.net\\xstudio2\\storage"
            options = "-o anon"
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
            options = "-o anon"
            userName = ""
            password = ""
          }
        },
        { # Job Scheduler
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
            source  = "anf-volume1.azure.studio:/volume1"
            options = "vers=3,hard,tcp"
          }
        },
        { # File Cache
          enable = false
          mount = {
            type    = "nfs"
            path    = "/mnt/storage"
            source  = "cache.azure.studio:/storage"
            options = "vers=3,hard,tcp"
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
            options = "-o anon"
            userName = ""
            password = ""
          }
        },
        { # Job Scheduler
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
