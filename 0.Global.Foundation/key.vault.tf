############################################################################
# Key Vault (https://learn.microsoft.com/azure/key-vault/general/overview) #
############################################################################

variable keyVault {
  type = object({
    type                        = string
    enableForDeployment         = bool
    enableForDiskEncryption     = bool
    enableForTemplateDeployment = bool
    enablePurgeProtection       = bool
    enableTrustedServices       = bool
    softDeleteRetentionDays     = number
    secrets = list(object({
      name  = string
      value = string
    }))
    keys = list(object({
      name       = string
      type       = string
      size       = number
      operations = list(string)
    }))
    certificates = list(object({
      name        = string
      subject     = string
      issuerName  = string
      contentType = string
      validMonths = number
      key = object({
        type       = string
        size       = number
        reusable   = bool
        exportable = bool
        usage      = list(string)
      })
    }))
  })
}

resource azurerm_role_assignment key_vault_reader {
  role_definition_name = "Key Vault Reader" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/security#key-vault-reader
  principal_id         = azurerm_user_assigned_identity.studio.principal_id
  scope                = azurerm_key_vault.studio.id
}

resource azurerm_role_assignment key_vault_crypto_service_encryption_user {
  role_definition_name = "Key Vault Crypto Service Encryption User" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/security#key-vault-crypto-service-encryption-user
  principal_id         = azurerm_user_assigned_identity.studio.principal_id
  scope                = azurerm_key_vault.studio.id
}

resource azurerm_key_vault studio {
  name                            = module.global.keyVault.name
  resource_group_name             = azurerm_resource_group.studio.name
  location                        = azurerm_resource_group.studio.location
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  sku_name                        = var.keyVault.type
  enabled_for_deployment          = var.keyVault.enableForDeployment
  enabled_for_disk_encryption     = var.keyVault.enableForDiskEncryption
  enabled_for_template_deployment = var.keyVault.enableForTemplateDeployment
  purge_protection_enabled        = var.keyVault.enablePurgeProtection
  soft_delete_retention_days      = var.keyVault.softDeleteRetentionDays
  enable_rbac_authorization       = true
  network_acls {
    bypass         = var.keyVault.enableTrustedServices ? "AzureServices" : "None"
    default_action = "Deny"
    ip_rules = [
      "${jsondecode(data.http.client_address.response_body).ip}/32"
    ]
  }
}

resource azurerm_key_vault_secret studio {
  for_each = {
    for secret in var.keyVault.secrets : secret.name => secret
  }
  name         = each.value.name
  value        = each.value.value
  key_vault_id = azurerm_key_vault.studio.id
}

resource azurerm_key_vault_key studio {
  for_each = {
    for key in var.keyVault.keys : key.name => key
  }
  name         = each.value.name
  key_type     = each.value.type
  key_size     = each.value.size
  key_opts     = each.value.operations
  key_vault_id = azurerm_key_vault.studio.id
}

resource azurerm_key_vault_certificate studio {
  for_each = {
    for certificate in var.keyVault.certificates : certificate.name => certificate
  }
  name         = each.value.name
  key_vault_id = azurerm_key_vault.studio.id
  certificate_policy {
    x509_certificate_properties {
      subject            = each.value.subject
      key_usage          = each.value.key.usage
      validity_in_months = each.value.validMonths
    }
    issuer_parameters {
      name = each.value.issuerName
    }
    secret_properties {
      content_type = each.value.contentType
    }
    key_properties {
      key_type = each.value.key.type
      key_size = each.value.key.size
      reuse_key = each.value.key.reusable
      exportable = each.value.key.exportable
    }
  }
}

data tls_public_key ssh_key {
  private_key_pem = tls_private_key.ssh_key.private_key_pem
}

resource tls_private_key ssh_key {
  algorithm = var.keyVault.keys[0].type
  rsa_bits  = var.keyVault.keys[0].size
}

resource azurerm_key_vault_secret ssh_key_private {
  name         = module.global.keyVault.secretName.sshKeyPrivate
  value        = tls_private_key.ssh_key.private_key_pem
  key_vault_id = azurerm_key_vault.studio.id
}

resource azurerm_key_vault_secret ssh_key_public {
  name         = module.global.keyVault.secretName.sshKeyPublic
  value        = trimspace(data.tls_public_key.ssh_key.public_key_openssh)
  key_vault_id = azurerm_key_vault.studio.id
}
