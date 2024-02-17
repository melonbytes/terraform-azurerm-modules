output "location" { value = var.location }

output "resource_group" { value = var.resource_group }

output "vm_size" { value = var.vm_size }

output "role" { value = var.role }

output "publisher" { value = lookup(var.publisher, var.role) }
output "offer" { value = lookup(var.offer, var.role) }
output "os_sku" { value = lookup(var.sku, var.role) }
output "image_version" { value = lookup(var.image_version, var.role) }

output "private_ip_address" {
  value = {
      for nic in azurerm_network_interface.nic:
      nic.name => nic.private_ip_address
  }
}

output "public_ip_address" {
  value = {
    for pipdata in data.azurerm_public_ip.ip:
    pipdata.name => pipdata.ip_address
  }
}

### The Ansible inventory file
### https://www.linkbynet.com/produce-an-ansible-inventory-with-terraform
resource "local_file" "AnsibleInventory" {
  content = templatefile("${path.module}/inventory.tmpl",
  {
    #instances = local.instances_list
    #instances = azurerm_virtual_machine.vm.*.name
    environment_nickname = var.environment_nickname
    role = var.role
    private_ip_address = azurerm_network_interface.nic
    public_ip_address = data.azurerm_public_ip.ip
  }
  )
  filename = "${path.module}/../../../inventory/${var.environment_nickname}/${var.resource_group}.hosts"
}

resource "local_file" "AnnsibleGroupVar" {
  content = templatefile("${path.module}/group_vars.tmpl",
  {
    bastion_address = var.bastion_address[0]
  }
  )
  filename = "${path.module}/../../../inventory/group_vars/${var.environment_nickname}/${var.role}.yml"
  count = var.role == "bastion" || var.require_bastion == false ? 0 : 1
}