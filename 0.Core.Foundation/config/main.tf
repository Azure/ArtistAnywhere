output image {
  value = {
    linux = {
      enable    = true
      publisher = "AlmaLinux"
      offer     = "AlmaLinux-x86_64"
      sku       = "9-Gen2"
      version   = "9.5.202411260"
    }
    windows = {
      enable  = true
      version = "Latest"
    }
  }
}

output hammerspace {
  value = {
    enable     = false
    version    = "24.06.19"
    namePrefix = "xstudio"
    domainName = "azure.studio"
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
        enable = false
        name   = ""
        path   = ""
        size   = 0
        export = "*,rw,no-root-squash"
      }
    ]
    volumes = [
      {
        enable = false
        name   = ""
        type   = "READ_WRITE"
        path   = ""
        node = {
          name    = ""
          type    = ""
          address = ""
        }
        assimilation = {
          enable = false
          share = {
            name = ""
            path = {
              source      = ""
              destination = ""
            }
          }
        }
      }
    ]
    volumeGroups = [
      {
        enable = false
        name   = ""
        volumeNames = [
        ]
      }
    ]
  }
}
