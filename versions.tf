terraform {
  required_version = ">= 1.5.0"
  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.8.1, < 3.0"
    }
    oci = {
      source  = "oracle/oci"
      version = ">= 7.0, < 8.0"
    }
  }
}

provider "oci" {
  region = var.region
}
