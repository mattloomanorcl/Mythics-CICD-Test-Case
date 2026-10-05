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
  type    = bool
  default = false
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
  type    = bool
  default = false
}
variable "existing_bucket_name" {
  type    = string
  default = ""
}
variable "bucket_name" {
  type    = string
  default = ""
}
variable "par_expiration_days" {
  type        = number
  default     = 30
  description = "Number of days the developer script pre-authenticated request remains valid after apply."
  validation {
    condition     = var.par_expiration_days >= 1 && floor(var.par_expiration_days) == var.par_expiration_days
    error_message = "Script link lifetime must be a whole number of days greater than zero."
  }
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
variable "developer_oci_profile" {
  type    = string
  default = "DEFAULT"
}
