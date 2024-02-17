#
# Azure application gateway resource creation script
#
# Author:   Ray Bramwell
# Created:  11th May 2021
# Modified: 2nd July 2021
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

# Represent unmanaged SharedInfrastructure-RG
data "azurerm_resource_group" "sirg" {
  name     = var.vnet_rg_name
}

# Represent unmanaged virtual network
data "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  resource_group_name = data.azurerm_resource_group.sirg.name
}

# Represent unmanaged subnet(s)
data "azurerm_subnet" "backend" {
  name                 = var.subnet_names[0]
  resource_group_name  = data.azurerm_resource_group.sirg.name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
}
data "azurerm_subnet" "frontend" {
  name                 = var.subnet_names[1]
  resource_group_name  = data.azurerm_resource_group.sirg.name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
}

# Represent resource group
data "azurerm_resource_group" "rg" {
  name     = var.resource_group
}





# https://faun.pub/build-an-azure-application-gateway-with-terraform-8264fbd5fa42

# -
# - Managed Service Identity
# -

resource "azurerm_user_assigned_identity" "agw" {
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  name                = var.user_assigned_identity_name
  tags                = local.tags
}

resource "azurerm_key_vault_access_policy" "agw" {
  key_vault_id = var.key_vault_id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.agw.principal_id

  secret_permissions = [
    "get"
  ]
  depends_on = [ azurerm_user_assigned_identity.agw ]
}


# Create public IP
resource "azurerm_public_ip" "publicip" {
  name                = "${var.application_gateway_name}-PublicIP"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Static"      # Dynamic, Static
  sku                 = "Standard"    # Basic, Standard
  tags                = local.tags
}




# Create applicationgateway
resource "azurerm_application_gateway" "applicationgateway" {
  name                = var.application_gateway_name
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.location
  tags                = local.tags
  zones               = var.zones

  sku {
    name     = "WAF_v2" # Standard_Small, WAF_v2
    tier     = "WAF_v2" # Standard, WAF_v2
  }

  gateway_ip_configuration {
    name      = "${var.application_gateway_name}-IpConfig"
    subnet_id = data.azurerm_subnet.frontend.id
  }

  ssl_certificate {
    name  = var.key_vault_certificate_name
    key_vault_secret_id = var.key_vault_certificate_secret_id
  }

  trusted_root_certificate {
    name  = var.trusted_root_certificate_name
    data  = filebase64(var.trusted_root_certificate_path)
  }

  frontend_ip_configuration {
    name                  = "${var.application_gateway_name}-FrontendIpConfig"
    public_ip_address_id  = azurerm_public_ip.publicip.id
  }

  frontend_port {
    name = "${var.application_gateway_name}-HTTP"
    port = 80
  }

  frontend_port {
    name = "${var.application_gateway_name}-HTTPS"
    port = 443
  }

  backend_address_pool {
    name          = var.backend_address_pool_name
    ip_addresses  = var.backend_address_pool_ip_addresses
  }

  backend_http_settings {
    name                  = "${var.backend_address_pool_name}-HTTP-Settings"
    cookie_based_affinity = var.cookie_based_affinity
    path                  = "/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 20
    connection_draining {
      enabled             = true
      drain_timeout_sec   = 60
    }
    affinity_cookie_name  = "ApplicationGatewayAffinity"
  }

  backend_http_settings {
    name                  = "${var.backend_address_pool_name}-HTTPS-Settings"
    cookie_based_affinity = var.cookie_based_affinity
    path                  = "/"
    port                  = 443
    protocol              = "Https"
    request_timeout       = 20
    connection_draining {
      enabled             = true
      drain_timeout_sec   = 60
    }
    affinity_cookie_name  = "ApplicationGatewayAffinity"
    host_name             = "127.0.0.1"
    trusted_root_certificate_names = [var.trusted_root_certificate_name]
  }


  http_listener {
    name                            = "${var.application_gateway_name}-HTTP-Listner"
    frontend_ip_configuration_name  = "${var.application_gateway_name}-FrontendIpConfig"
    frontend_port_name              = "${var.application_gateway_name}-HTTP"
    protocol                        = "Http"
    host_names                      = var.host_names
  }

  http_listener {
    name                            = "${var.application_gateway_name}-HTTPS-Listner"
    frontend_ip_configuration_name  = "${var.application_gateway_name}-FrontendIpConfig"
    frontend_port_name              = "${var.application_gateway_name}-HTTPS"
    protocol                        = "Https"
    host_names                      = var.host_names
    ssl_certificate_name            = var.key_vault_certificate_name
  }

  request_routing_rule {
    name                        = "${var.application_gateway_name}-HTTP-Default"
    rule_type                   = "Basic"
    http_listener_name          = "${var.application_gateway_name}-HTTP-Listner"
    backend_address_pool_name   = var.backend_address_pool_name
    backend_http_settings_name  = "${var.backend_address_pool_name}-HTTP-Settings"
    rewrite_rule_set_name       = "SetDefaultHeaders"
  }

  request_routing_rule {
    name                        = "${var.application_gateway_name}-HTTPS-Default"
    rule_type                   = "Basic"
    http_listener_name          = "${var.application_gateway_name}-HTTPS-Listner"
    backend_address_pool_name   = var.backend_address_pool_name
    backend_http_settings_name  = "${var.backend_address_pool_name}-HTTPS-Settings"
    rewrite_rule_set_name       = "SetDefaultHeaders"
  }

  rewrite_rule_set {
    name                      = "SetDefaultHeaders"
    rewrite_rule {
      name                      = "X-Forwarded-For"
      rule_sequence             = 100
      request_header_configuration {
        header_name               = "X-Forwarded-For"
        header_value              = "{var_add_x_forwarded_for_proxy}"
      }
    }
  }

  ssl_policy {
    policy_type               = "Predefined"
    policy_name               = "AppGwSslPolicy20170401"
  }

  waf_configuration {
    enabled                   = true
    firewall_mode             = "Prevention"
    rule_set_type             = "OWASP"
    rule_set_version          = "3.1"
  }

  autoscale_configuration {
    min_capacity = 0
    max_capacity = 3
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.agw.id]
  }
  depends_on = [ azurerm_user_assigned_identity.agw, azurerm_public_ip.publicip ]
}
