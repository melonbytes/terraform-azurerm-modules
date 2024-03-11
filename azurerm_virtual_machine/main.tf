#
# Azure workload resource creation script
#
# Author:   Ray Bramwell
# Created:  20th March 2021
# Modified: 11th March 2024
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
  vm_datadiskdisk_count_map = { for k in toset(var.instances) : k => var.nb_disks_per_instance }
  luns                      = { for k in local.datadisk_lun_map : k.datadisk_name => k.lun }
  datadisk_lun_map = flatten([
    for vm_name, count in local.vm_datadiskdisk_count_map : [
      for i in range(count) : {
        datadisk_name = format("%s-DataDisk%02d", vm_name, i)
        lun           = i
      }
    ]
  ])
  instances_list = { for i in toset(var.instances) : i => azurerm_virtual_machine.vm[i] }

  nsg_security_rules = { for idx, security_rule in var.nsg_security_rules : security_rule.name => {
    idx : idx,
    security_rule : security_rule,
    }
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
data "azurerm_subnet" "subnet" {
  name                 = var.subnet_name
  resource_group_name  = data.azurerm_resource_group.sirg.name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
}

# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group
  location = var.location
  tags     = var.tags
  lifecycle {
    ignore_changes = [ 
      tags["CreatedDateTime"]
    ]
  }
}

# Create public IP
resource "azurerm_public_ip" "publicip" {
  name                = "${var.instances[count.index]}-PublicIP"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = var.public_ip_allocation_method
  tags                = var.tags
  lifecycle {
    ignore_changes = [ 
      tags["CreatedDateTime"]
    ]
  }
  count = var.create_public_ip ? length(var.instances) : 0
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "nsg" {
  for_each = toset(var.instances)
  name                = "${each.value}-NSG"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
  lifecycle {
    ignore_changes = [ 
      tags["CreatedDateTime"]
    ]
  }

  
  dynamic "security_rule" {
    for_each                        = local.nsg_security_rules
    content {
      name                          = security_rule.key
      priority                      = 100 * (security_rule.value.idx + 1)
      direction                     = lookup(security_rule.value.security_rule,"direction","")
      access                        = lookup(security_rule.value.security_rule,"access","")
      protocol                      = lookup(security_rule.value.security_rule,"protocol","")
      source_port_range             = lookup(security_rule.value.security_rule,"source_port_range","")
      source_port_ranges            = lookup(security_rule.value.security_rule,"source_port_ranges",[])
      destination_port_range        = lookup(security_rule.value.security_rule,"destination_port_range","")
      destination_port_ranges       = lookup(security_rule.value.security_rule,"destination_port_ranges",[])
      source_address_prefix         = lookup(security_rule.value.security_rule,"source_address_prefix","")
      source_address_prefixes       = lookup(security_rule.value.security_rule,"source_address_prefixes",[])
      destination_address_prefix    = lookup(security_rule.value.security_rule,"destination_address_prefix","")
      destination_address_prefixes  = lookup(security_rule.value.security_rule,"destination_address_prefixes",[])
    }
  }
}

# Create network interface
resource "azurerm_network_interface" "nic" {
  for_each = toset(var.instances)
  name                = "${each.value}-NIC"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
  lifecycle {
    ignore_changes = [ 
      tags["CreatedDateTime"]
    ]
  }

  ip_configuration {
    name                          = "${each.value}-NICConfg"
    primary                       = true
    subnet_id                     = data.azurerm_subnet.subnet.id
    private_ip_address_allocation = var.private_ip_allocation_method
    private_ip_address            = var.private_ip_allocation_method == "static" ? var.private_ip_addresses[index(var.instances,each.key)] : null
    public_ip_address_id          = var.create_public_ip ? azurerm_public_ip.publicip[index(var.instances,each.key)].id : null
  }
}

# Create a Linux virtual machine
resource "azurerm_virtual_machine" "vm" {
  for_each = toset(var.instances)
  name                  = each.value
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic[each.key].id]
  vm_size               = var.vm_size
  tags                  = var.tags
  lifecycle {
    ignore_changes = [ 
      tags["CreatedDateTime"]
    ]
  }

  storage_os_disk {
    name              = "${each.value}-OsDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = var.publisher
    offer     = var.offer
    sku       = var.sku
    version   = var.image_version
  }

  os_profile {
    computer_name  = each.value
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  dynamic "os_profile_linux_config" {
    for_each = var.os_family == "linux" ? [0] : []
    content {
      disable_password_authentication = var.disable_password_authentication
      dynamic "ssh_keys" {
        for_each = var.authorized_keys
        content {
          key_data = each.value
          path = var.admin_ssh_authorized_keys
        }
      }
    }
  }

  dynamic "os_profile_windows_config" {
    for_each = var.os_family == "windows" ? [0] : []
    content {
      provision_vm_agent        = true
      enable_automatic_upgrades = true
      timezone                  = "UTC"
      winrm {
        protocol  = "HTTP"
      }
    }
  }

  boot_diagnostics {
    enabled = true
    storage_uri = var.boot_diagnostics_storage_uri
  }
  
}

#
# Associate NICs with NSGs
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_security_group_association
#
resource "azurerm_network_interface_security_group_association" "nicnsg" {
  for_each = toset(var.instances)
  network_interface_id      = azurerm_network_interface.nic[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg[each.key].id
}

#
# Attach additional Data Disks
# https://www.nealshah.dev/posts/2020/05/terraform-for-azure-deploying-multiple-vms-with-multiple-managed-disks/
#
resource "azurerm_managed_disk" "managed_disk" {
  for_each             = toset([for j in local.datadisk_lun_map : j.datadisk_name])
  name                 = each.key
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = var.data_disk_storage_account_type
  create_option        = "Empty"
  disk_size_gb         = var.data_disk_size_gb
  tags                 = var.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "managed_disk_attach" {
  for_each           = toset([for j in local.datadisk_lun_map : j.datadisk_name])
  managed_disk_id    = azurerm_managed_disk.managed_disk[each.key].id
  virtual_machine_id = azurerm_virtual_machine.vm[element(split("-DataDisk", each.key), 0)].id
  lun                = lookup(local.luns, each.key)
  caching            = var.data_disk_cache
}

#
# Post deployment output data
#
data "azurerm_public_ip" "ip" {
  name                = azurerm_public_ip.publicip[count.index].name
  resource_group_name = azurerm_virtual_machine.vm[var.instances[count.index]].resource_group_name
  depends_on = [local.instances_list]
  count = var.create_public_ip ? length(var.instances) : 0
}


#
# Basic resource creation script derived from numerous resources
#
# https://github.com/hashicorp/learn-terraform-azure
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_security_group_association
# https://www.nealshah.dev/posts/2020/05/terraform-for-azure-deploying-multiple-vms-with-multiple-managed-disks/
# https://stackoverflow.com/questions/53770872/terraform-public-ip-output-on-azure
#
