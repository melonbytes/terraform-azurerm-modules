#
# Azure CDN creation script
#
# Author:   Ray Bramwell
# Created:  17th Jun 2021
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

# CDN Endpoints
resource "azurerm_cdn_profile" "cdnprofile" {
  count               = length(var.cdn_profile_name) != 0 ? 1 : 0
  name                = var.cdn_profile_name
  resource_group_name = var.resource_group
  location            = "global"
  tags                = local.tags
  sku                 = var.cdn_profile_sku
}
resource "azurerm_cdn_endpoint" "cdnendpoint" {
  count                     = length(var.cdn_endpoints)
  name                      = var.cdn_endpoints[count.index].name
  profile_name              = azurerm_cdn_profile.cdnprofile[0].name
  resource_group_name       = var.resource_group
  location                  = azurerm_cdn_profile.cdnprofile[0].location
  tags                      = local.tags
  is_compression_enabled    = var.is_compression_enabled
  content_types_to_compress = var.content_types_to_compress
  origin_path               = var.cdn_endpoints[count.index].origin_path
  origin_host_header        = var.cdn_endpoints[count.index].origin_host_name
  origin {
    name        = var.cdn_endpoints[count.index].origin_name
    host_name   = var.cdn_endpoints[count.index].origin_host_name
  }
}
