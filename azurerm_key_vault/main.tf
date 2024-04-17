#
# Azure key vault resource creation script
#
# Author:   Ray Bramwell
# Created:  12th May 2021
# Modified: 18th February 2024
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

provider "azurerm" {
  features {
    key_vault {
      purge_soft_deleted_secrets_on_destroy = true
      recover_soft_deleted_secrets          = true
    }
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
  tags                        = var.tags
  lifecycle {
    ignore_changes = [ 
      tags["CreatedDateTime"]
    ]
  }
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = var.key_vault_sku_name
  enable_rbac_authorization   = var.enable_rbac_authorization
}


resource "azurerm_key_vault_access_policy" "builder" {
    key_vault_id = azurerm_key_vault.keyvault.id
    tenant_id    = data.azurerm_client_config.current.tenant_id
    object_id    = data.azurerm_client_config.current.object_id

    certificate_permissions = [
      "Get",
    ]

    key_permissions = [
      "Get",
    ]

    secret_permissions = [
      "Get",
    ]

}