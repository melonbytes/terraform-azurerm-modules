#
# Azure key vault resource creation script
#
# Author:   Ray Bramwell
# Created:  12th May 2021
# Modified: 12th July 2021
#


# Configure the Microsoft Azure Provider.
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 2.26"
    }
  }
}

locals {
  tags = {
    Environment     = var.tags.Environment
    BusinessUnit    = var.tags.BusinessUnit
    Service         = var.tags.Service
    System          = var.tags.System
    SystemOwner     = var.tags.SystemOwner
    CreatedBy       = var.tags.CreatedBy
    CreatedDateTime = formatdate("DD/MM/YYYY hh:mm:ss",timestamp())
    Terraform       = true
  }
}

data "azurerm_client_config" "current" {}

# Represent resource group
data "azurerm_resource_group" "rg" {
  name     = var.resource_group
}



resource "azurerm_key_vault" "keyvault" {
  name                        = var.key_vault_name
  location                    = data.azurerm_resource_group.rg.location
  resource_group_name         = data.azurerm_resource_group.rg.name
  tags                        = local.tags
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = var.key_vault_sku_name
}


resource "azurerm_key_vault_access_policy" "builder" {
    key_vault_id = azurerm_key_vault.keyvault.id
    tenant_id    = data.azurerm_client_config.current.tenant_id
    object_id    = data.azurerm_client_config.current.object_id

    certificate_permissions = [
      "create",
      "delete",
      "deleteissuers",
      "get",
      "getissuers",
      "import",
      "list",
      "listissuers",
      "managecontacts",
      "manageissuers",
      "setissuers",
      "update",
      "purge",
    ]

    key_permissions = [
      "backup",
      "create",
      "decrypt",
      "delete",
      "encrypt",
      "get",
      "import",
      "list",
      "purge",
      "recover",
      "restore",
      "sign",
      "unwrapKey",
      "update",
      "verify",
      "wrapKey",
    ]

    secret_permissions = [
      "backup",
      "delete",
      "get",
      "list",
      "purge",
      "recover",
      "restore",
      "set",
    ]

}

#############################################


resource "azurerm_key_vault_certificate" "keyvault" {
  name          = var.key_vault_certificate_name
  key_vault_id = azurerm_key_vault.keyvault.id

  certificate {
    contents = filebase64(var.key_vault_certificate_path)
    password = ""
  }

  certificate_policy {
    issuer_parameters {
      #name = "Self"
      name = "Unknown"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = false
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }
  }
  depends_on = [ azurerm_key_vault_access_policy.builder ]
}

resource "azurerm_key_vault_secret" "secret" {
  count         = length(var.key_vault_secrets)
  key_vault_id  = azurerm_key_vault.keyvault.id
  name          = var.key_vault_secrets[count.index].name
  value         = var.key_vault_secrets[count.index].value
  depends_on    = [ azurerm_key_vault_access_policy.builder ]
}

resource "azurerm_key_vault_access_policy" "appregistration" {
  count                   = length(var.key_vault_access_policies)
  key_vault_id            = azurerm_key_vault.keyvault.id
  object_id               = var.key_vault_access_policies[count.index].object_id
  tenant_id               = var.key_vault_access_policies[count.index].tenant_id
  certificate_permissions = var.key_vault_access_policies[count.index].certificate_permissions
  key_permissions         = var.key_vault_access_policies[count.index].key_permissions
  secret_permissions      = var.key_vault_access_policies[count.index].secret_permissions
  depends_on              = [ azurerm_key_vault_access_policy.builder ]
}