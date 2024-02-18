
output "virtual_network_gateway_public_ip" {
  value = azurerm_public_ip.vng_pip[*].name
}

output "virtual_network_gateway_id" {
  value = azurerm_virtual_network_gateway.vng.id
}

output "virtual_network_gateway" {
  value = azurerm_virtual_network_gateway.vng.name
}