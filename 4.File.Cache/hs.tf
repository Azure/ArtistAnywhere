######################################################################################################
# Hammerspace (https://azuremarketplace.microsoft.com/marketplace/apps/hammerspace.hammerspace-byol) #
######################################################################################################

module hsCache {
  count       = var.hsCache.enable ? 1 : 0
  source      = "../3.File.Storage/Hammerspace"
  hammerspace = var.hsCache
  resourceGroup = {
    name     = azurerm_resource_group.cache.name
    location = azurerm_resource_group.cache.location
  }
  virtualNetwork = {
    name              = data.azurerm_subnet.cache.virtual_network_name
    subnetName        = data.azurerm_subnet.cache.name
    resourceGroupName = data.azurerm_subnet.cache.resource_group_name
  }
  privateDNS = {
    zoneName          = data.azurerm_private_dns_zone.studio.name
    resourceGroupName = data.azurerm_private_dns_zone.studio.resource_group_name
    aRecord = {
      name       = var.dnsRecord.name
      ttlSeconds = var.dnsRecord.ttlSeconds
    }
  }
  adminLogin = {
    userName     = data.azurerm_key_vault_secret.admin_username.value
    userPassword = data.azurerm_key_vault_secret.admin_password.value
    sshKeyPublic = data.azurerm_key_vault_secret.ssh_key_public.value
  }
  activeDirectory = {
    enable       = var.activeDirectory.enable
    domainName   = var.activeDirectory.domain.name
    servers      = var.activeDirectory.machine.name
    userName     = var.activeDirectory.machine.adminLogin.userName != "" ? var.activeDirectory.machine.adminLogin.userName : data.azurerm_key_vault_secret.admin_username.value
    userPassword = var.activeDirectory.machine.adminLogin.userPassword != "" ? var.activeDirectory.machine.adminLogin.userPassword : data.azurerm_key_vault_secret.admin_password.value
  }
  depends_on = [
    azurerm_resource_group.cache
  ]
}

variable hsCache {
  type = object({
    enable     = bool
    version    = string
    namePrefix = string
    domainName = string
    metadata = object({
      machine = object({
        namePrefix = string
        size       = string
        count      = number
        osDisk = object({
          storageType = string
          cachingMode = string
          sizeGB      = number
        })
        dataDisk = object({
          storageType = string
          cachingMode = string
          sizeGB      = number
        })
        adminLogin = object({
          userName     = string
          userPassword = string
          sshKeyPublic = string
          passwordAuth = object({
            disable = bool
          })
        })
      })
      network = object({
        acceleration = object({
          enable = bool
        })
      })
    })
    data = object({
      machine = object({
        namePrefix = string
        size       = string
        count      = number
        osDisk = object({
          storageType = string
          cachingMode = string
          sizeGB      = number
        })
        dataDisk = object({
          storageType = string
          cachingMode = string
          sizeGB      = number
          count       = number
          raid0 = object({
            enable = bool
          })
        })
        adminLogin = object({
          userName     = string
          userPassword = string
          sshKeyPublic = string
          passwordAuth = object({
            disable = bool
          })
        })
      })
      network = object({
        acceleration = object({
          enable = bool
        })
      })
    })
    proximityPlacementGroup = object({
      enable = bool
    })
    storageAccounts = list(object({
      enable    = bool
      name      = string
      accessKey = string
    }))
    shares = list(object({
      enable = bool
      name   = string
      path   = string
      size   = number
      export = string
    }))
    volumes = list(object({
      enable = bool
      name   = string
      type   = string
      path   = string
      node = object({
        name    = string
        type    = string
        address = string
      })
      assimilation = object({
        enable = bool
        share = object({
          name = string
          path = object({
            source      = string
            destination = string
          })
        })
      })
    }))
    volumeGroups = list(object({
      enable      = bool
      name        = string
      volumeNames = list(string)
    }))
  })
}
