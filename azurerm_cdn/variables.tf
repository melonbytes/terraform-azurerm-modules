variable "resource_group" {
    type        = string
    description = "Resource Group container for general resources"
}

variable "tags" {
    type = map
}

variable "cdn_profile_name" {
    type        = string
    description = "Specifies the name of the CDN Profile. Changing this forces a new resource to be created."
    default     = ""
}

variable "cdn_profile_sku" {
    type        = string
    description = "The pricing related information of current CDN profile. Accepted values are Standard_Akamai, Standard_ChinaCdn, Standard_Microsoft, Standard_Verizon or Premium_Verizon."
    default     = "Standard_Akamai"
}

variable "cdn_endpoints" {
    type        = list(map(string))
    description = "Specifies the names of the CDN Endpoints. Changing this forces a new resource to be created."
    default     = []
}

variable "is_compression_enabled" {
    type        = bool
    description = "Indicates whether compression is to be enabled"
    default     = false
}

variable "content_types_to_compress" {
    type        = list(string)
    description = "An array of strings that indicates a content types on which compression will be applied. The value for the elements should be MIME types."
    default     = ["text/plain","text/html","text/css","text/javascript","applicaion/x-javascript","applicaion/javascript","applicaion/json","applicaion/xml"]
}