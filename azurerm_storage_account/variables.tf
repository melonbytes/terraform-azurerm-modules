variable "location" {}

variable "resource_group" {
  type        = string
  description = "Resource Group container for general resources"
}

variable "tags" {
  type = map
}
variable "storage_account_name" {
  type        = string
  description = "Storage Account Name."
}
variable "account_kind" {
  type        = string
  description = "Storage Account Kind (BlobStorage, BlockBlobStorage, FileStorage, Storage or StorageV2)."
  default     = "StorageV2"
}
variable "account_tier" {
  type        = string
  description = "Storage Account Tier (Standard or Premium)."
  default     = "Standard"
}
variable "account_replication_type" {
  type        = string
  description = "Storage Account Replication Type (LRS, GRS, RAGRS, ZRS, GZRS or RAGZRS)."
  default     = "LRS"
}
variable "min_tls_version" {
  type        = string
  description = "Determine the Minimum TLS version (TLS1_0, TLS1_1 or TLS1_2)."
  default     = "TLS1_0"
}

variable "containers" {
  type        = list(map(string))
  description = "Maps of Storage Account Container Names and Access Types."
  default     = []
}

variable "allow_blob_public_access" {
  type          = bool
  description   = "Determines whether the storage account will permit any blobs to be publicly accessible"
  default       = false
}

variable "custom_domains" {
  type          = list(string)
  description   = "List custom domains to configure"
  default       = []
}

variable "create_blobfuse_config" {
  type          = bool
  description   = "Determines whether a blobfuse-config file will be generated. (Uses the first storage container defined)"
  default       = false
}
