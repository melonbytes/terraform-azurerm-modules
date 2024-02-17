variable "vnet_rg_name" {
  type        = string
}

variable "location" {}
variable "environment_nickname" {}

variable "resource_group" {
  type        = string
  description = "Resource Group container for general resources"
}

variable "instances" {
  type        = list(string)
  description = "Virtual Machine instance names."
}

variable "nb_disks_per_instance" {
  description = "Number of additional disks to create per instance."
  type        = number
  default     = 1
}

variable "data_disk_size_gb" {
  description = "Data disk size (expressed in GBs)"
  type        = number
  default     = 32
}

variable "data_disk_storage_account_type" {
  description = "Storage account type, (Possible values are Standard_LRS, Premium_LRS, StandardSSD_LRS or UltraSSD_LRS)"
  type        = string
  default     = "Standard_LRS"
}

variable "data_disk_cache" {
  description = "Specifies the caching requirements for this Data Disk. (Possible values include None, ReadOnly and ReadWrite)."
  type        = string
  default     = "ReadWrite"
}

variable "tags" {
  type = map
}

#
# Network Variables
#
variable "vnet_name" {
  description = "Name of the vnet to create"
  type        = string
  default     = "acctvnet"
}

variable "subnet_name" {
  description = "Subnet to inside the vNet to which we will attach our NICs."
  type        = string
  default     = "AzureInternal"
}

#
# Access Variables
#
variable "admin_username" {
  type        = string
  description = "Administrator user name for virtual machine"
}

variable "admin_password" {
  type        = string
  description = "Administrator password for virtual machine"
  default     = null
}

variable "admin_ssh_authorized_keys" {
  type        = string
  description = "Administrator SSH authorized keys file for virtual machine"
  default     = null
}


#
# Image Variables
#
variable "vm_size" {
  type        = string
  description = "Virtual Machine size"
  default     = "Standard_DS1_v2"
}

variable "role" {
  type        = string
  default     = "generic"
}

variable "publisher" {
  default = {
    generic   = "OpenLogic"
    webserver = "OpenLogic"
    appserver = "OpenLogic"
    dbserver  = "OpenLogic"
    bastion   = "OpenLogic"
    linux     = "OpenLogic"
    windows   = "MicrosoftWindowsServer"
  }
}

variable "offer" {
  default = {
    generic   = "CentOS"
    webserver = "CentOS"
    appserver = "CentOS"
    dbserver  = "CentOS"
    bastion   = "CentOS"
    linux     = "CentOS"
    windows   = "WindowsServer"
  }
}

variable "sku" {
  default = {
    generic   = "8_3"
    webserver = "8_3"
    appserver = "8_3"
    dbserver  = "8_3"
    bastion   = "8_3"
    linux     = "8_3"
    windows   = "2016-Datacenter-smalldisk"
  }
}

variable "image_version" {
  default = {
    generic   = "latest"
    webserver = "latest"
    appserver = "latest"
    dbserver  = "latest"
    bastion   = "latest"
    linux     = "latest"
    windows   = "latest"
  }
}

variable "create_public_ip" {
  type          = bool
  default       = false
}
variable "bastion_address" {
  type        = list(string)
  description = "Bastion's Public IP"
  default     = []
}

variable "boot_diagnostics_storage_uri" {
  description = "Boot Diagnostics Storage URI"
  type        = string
}

variable "public_ip_allocation_method" {
  description = "IP Address allocation method, (Dynamic or Static)."
  type        = string
  default     = "Dynamic"
}

variable "private_ip_allocation_method" {
  description = "IP Address allocation method, (dynamic or static)."
  type        = string
  default     = "dynamic"
}

variable "private_ip_addresses" {
  type        = list(string)
  description = "List of Static IP Address which should be used. This is valid only when `private_ip_allocation_method` is set to `Static`."
  default = null
}

variable "nsg_security_rules" {
  description = "List of network rules to apply to network interface."
  default     = []
}

variable "require_bastion" {
  type          = bool
  default       = false
}

variable "os_family" {
  description = "OS Family, (linux or windows)"
  type        = string
  default     = "linux"
}