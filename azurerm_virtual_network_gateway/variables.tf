variable "tags" {
  type = map
}

variable "location" {
    type        = string
    description = "Location name"
}

variable "resource_group_name" {
    type        = string
    description = "Resource Group name"
}

variable "subnet_id" {
    type        = string
    description = "Gateway Subnet ID"
}

variable "vng_public_ips" {
    type        = string
    description = "Number of Public IP addresses required, (e.g. Active/Active fault tollerence requires an additional Public IP, some VPN types require yet another)"
    default     = "1"
}

variable "zones" {
    type        = list(string)
    description = "Availability Zones (e.g. [ \"1\" ])"
    default     = [ "1" ]
}

variable "name" {
    type        = string
    description = "Virtual Network Gateway instance name"
}

variable "type" {
    type        = string
    description = "Virtual Network Gateway Type (e.g. Vpn)"
    default     = "Vpn"
}

variable "vpn_type" {
    type        = string
    description = "VPN Type (e.g. RouteBased, PolicyBased)"
    default     = "RouteBased"
}

variable "generation" {
    type        = string
    description = "Virtual Network Gateway Generation (e.g. Generation1, Generation2)"
    default     = "Generation1"
}

variable "sku" {
    type        = string
    description = "Virtual Network Gateway SKU (e.g. Basic, VpnGw1, VpnGw2, VpnGw2AZ)"
    default     = "Basic"
}

variable "active_active" {
    type        = bool
    description = "Switch to enable Active/Active fault tollerance switch, defaults to Active/Standby"
    default     = false
}

variable "enable_bgp" {
    type        = bool
    description = "Switch to enable BGP routing protocol"
    default     = false
}

variable "bgp_asn_number" {
    type        = string
    description = "BGP ASN Number"
    default     = ""
}

variable "client_address_space" {
    type        = list(string)
    description = "VPN Client Address Space"
}
variable "client_protocols" {
    type        = list(string)
    description = "VPN Client Protocols (e.g. OpenVPN)"
    default     = ["OpenVPN"]
}

variable "auth_types" {
    type        = list(string)
    description = "VPN Authentication Types (e.g. AAD)"
    default     = ["AAD"]
}

variable "tenant_id" {
  type        = string
  default     = ""
  description = "Microsoft Azure Tenant ID"
}