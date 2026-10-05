variable "tenancy_ocid" {
  type = string
}
variable "region" { type = string }
variable "compartment_ocid" { type = string }
variable "name_prefix" {
  type = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,20}$", var.name_prefix))
    error_message = "Use 3 to 21 lowercase letters, numbers, or hyphens, starting with a letter."
  }
}
variable "network_choice" {
  type    = string
  default = "Define"
  validation {
    condition     = contains(["Select", "Define"], var.network_choice)
    error_message = "Choose Select or Define."
  }
}
variable "existing_subnet_ocid" {
  type    = string
  default = ""
}
variable "existing_vcn_ocid" {
  type        = string
  default     = ""
  description = "Used by Resource Manager's subnet selector."
}
variable "vcn_cidr" {
  type    = string
  default = "10.42.0.0/16"
}
variable "subnet_cidr" {
  type    = string
  default = "10.42.1.0/24"
}
variable "bucket_choice" {
  type    = string
  default = "Define"
  validation {
    condition     = contains(["Select", "Define"], var.bucket_choice)
    error_message = "Choose Select or Define."
  }
}
variable "existing_bucket_name" {
  type    = string
  default = ""
}
variable "bucket_name" {
  type    = string
  default = ""
}
variable "par_expiration" {
  type        = string
  description = "RFC3339 timestamp for the developer script pre-authenticated request expiry."
}
variable "function_name" {
  type    = string
  default = "function"
}
variable "function_memory_mb" {
  type    = number
  default = 256
  validation {
    condition     = var.function_memory_mb >= 128 && var.function_memory_mb <= 3072 && var.function_memory_mb % 128 == 0
    error_message = "Function memory must be 128 through 3072 MB in 128 MB steps."
  }
}
variable "enable_function_deployment" {
  type        = bool
  default     = false
  description = "Set true only after the first image has been delivered to OCIR."
}
variable "developer_identity_domain" {
  type        = string
  description = "Identity domain name used in the developer's OCIR login."
}
variable "developer_user_name" {
  type        = string
  description = "OCI user name used in the developer's OCIR login."
}
variable "developer_oci_profile" {
  type    = string
  default = "DEFAULT"
}
variable "tenancy_name" { type = string }
variable "region_key" { type = string }
