variable "vnet_rg_name" {
  type        = string
}

variable "location" {}

variable "resource_group" {
  type        = string
  description = "Resource Group container for general resources"
}

variable "application_gateway_name" {
  type        = string
  description = "Application Gateway name."
}

variable "tags" {
  type = map
}


#
# Application Gateway Variables
#
variable "backend_address_pool_name" {
  type        = string
}
variable "host_names" {
  description = "A list of up to 5 Hostnames that should be used for this HTTP Listener. It allows special wildcard characters."
  type        = list(string)
}
variable "zones" {
  type        = list(string)
  description = "A collection of availability zones to spread the Application Gateway over"
  default     = ["1","2","3"]
}
variable "backend_address_pool_ip_addresses" {
  default     = {}
}
variable "key_vault_certificate_secret_id" {
  type        = string
  default     = ""
}
variable "key_vault_certificate_name" {
    type      = string
}
variable "key_vault_id" {
  type        = string
}
variable "user_assigned_identity_name" {
  type        = string
  default     = "agw-msi"
}
variable "trusted_root_certificate_name" {
  type        = string
}
variable "trusted_root_certificate_path" {
  type        = string
}

variable "cookie_based_affinity" {
  description = "Is Cookie-Based Affinity enabled? Possible values are Enabled and Disabled."
  default     = "Disabled"
}

#
# Network Variables
#
variable "vnet_name" {
  description = "Name of the vnet to create"
  type        = string
  default     = "acctvnet"
}

variable "subnet_names" {
  description = "A list of public subnets inside the vNet."
  type        = list(string)
}
