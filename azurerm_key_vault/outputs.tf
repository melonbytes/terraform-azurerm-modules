output "key_vault_id" { value = azurerm_key_vault.keyvault.id }

output "key_vault" { value = azurerm_key_vault.keyvault.name }

output "current" { value = data.azurerm_client_config.current }