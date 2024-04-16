output "primary_blob_endpoint" { value = azurerm_storage_account.storageaccount.primary_blob_endpoint }
output "primary_blob_host" { value = azurerm_storage_account.storageaccount.primary_blob_host }

resource "local_file" "blobfuse-config" {
  content = templatefile("${path.module}/blobfuse-config.tmpl",
  {
    storageaccount_name = azurerm_storage_account.storageaccount.name
    storageaccount_key = azurerm_storage_account.storageaccount.primary_access_key
    storageaccount_container_name = azurerm_storage_container.storagecontainer[count.index].name
  }
  )
  filename = "${path.module}/../../../files/secret/blobfuse-config.${var.containers[count.index].name}"
  count = var.create_blobfuse_config ? length(var.containers) : 0
}

output "name" { value = azurerm_storage_account.storageaccount.name }
output "primary_access_key" { value = azurerm_storage_account.storageaccount.primary_access_key  }