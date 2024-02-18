#
# Azure virtual network gateway creation script
#
# Author:   Ray Bramwell
# Created:  10th February 2024
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

data "azurerm_client_config" "current" {}

# Create Public IP(s)
resource "azurerm_public_ip" "vng_pip" {
  count               = var.vng_public_ips
  name                = "${format("%s-PublicIP-%02s", var.name, count.index + 1)}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
  lifecycle {
    ignore_changes = [ 
      tags["CreatedDateTime"]
     ]
  }
  sku                 = "Standard"
  allocation_method   = "Static"
  zones               = var.zones
}


# Create a Virtual Network Gateway
resource "azurerm_virtual_network_gateway" "vng" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
  lifecycle {
    ignore_changes = [ 
      tags["CreatedDateTime"]
     ]
  }

  type     = var.type
  vpn_type = var.vpn_type

  active_active = var.active_active
  enable_bgp    = var.enable_bgp
  generation    = var.generation
  sku           = var.sku

  ip_configuration {
    name                          = "vnetGatewayConfigPrimary"
    public_ip_address_id          = azurerm_public_ip.vng_pip[0].id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.subnet_id
  }

  dynamic "ip_configuration" {
    for_each = var.active_active ? [true] : []
    content {
      name                          = "vnetGatewayConfigSecondary"
      public_ip_address_id          = azurerm_public_ip.vng_pip[1].id
      private_ip_address_allocation = "Dynamic"
      subnet_id                     = var.subnet_id
    }
  }

  dynamic "ip_configuration" {
    for_each = var.vng_public_ips > 2 ? [true] : []
    content {
      name                          = "vnetGatewayConfigP2SVpn"
      public_ip_address_id          = azurerm_public_ip.vng_pip[2].id
      private_ip_address_allocation = "Dynamic"
      subnet_id                     = var.subnet_id
    }
  }

  dynamic "bgp_settings" {
    for_each = var.enable_bgp ? [true] : []
    content {
      asn = var.bgp_asn_number
    }
  }

  vpn_client_configuration {
    address_space         = var.client_address_space
    vpn_client_protocols  = var.client_protocols
    vpn_auth_types        = var.auth_types
    aad_tenant            = "https://login.microsoftonline.com/${var.tenant_id}/"
    aad_audience          = "41b23e61-6c1e-4545-b367-cd054e0ed4b4"
    aad_issuer            = "https://sts.windows.net/${var.tenant_id}/"
  }
}