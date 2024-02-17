#
# Azure storage account resource creation script
#
# Author:   Ray Bramwell
# Created:  10th Jun 2021
# Modified: 17th Jun 2021
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


# Create a storage account for web application shared storage
resource "azurerm_storage_account" "storageaccount" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group
  location                 = var.location
  account_kind             = var.account_kind
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  allow_blob_public_access = var.allow_blob_public_access
  min_tls_version          = var.min_tls_version
  tags                     = local.tags
  
  dynamic "custom_domain" {
    for_each = length(var.custom_domains) != 0 ? var.custom_domains : []
    content {
      name                          = custom_domain.value
    }
  }

}
resource "azurerm_storage_container" "storagecontainer" {
  count                 = length(var.containers)
  name                  = var.containers[count.index].name
  storage_account_name  = azurerm_storage_account.storageaccount.name
  container_access_type = var.containers[count.index].container_access_type
}
