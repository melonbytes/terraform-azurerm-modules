variable "location" {}

variable "resource_group" {
  type        = string
  description = "Resource Group container for general resources"
}

variable "tags" {
  type = map
}

variable "key_vault_name" {
  type        = string
  description = "Application Gateway name."
}

variable "key_vault_sku_name" {
  description = "The Name of the SKU used for this Key Vault. Possible values are standard and premium."
  default     = "premium"
}

variable "key_vault_access_policies" {
  description = "List of access policies to apply to key vault."
  default     = []
}

variable "key_vault_secrets" {
  description = "List of secrets to store in keyvault"
  default     = []
}

variable "enable_rbac_authorization" {
  description = "Boolean flag to specify whether Azure Key Vault uses Role Based Access Control (RBAC) for authorization of data actions"
  default = false
}