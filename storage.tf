resource "oci_objectstorage_bucket" "scripts" {
  count          = var.bucket_choice == "Define" ? 1 : 0
  compartment_id = var.compartment_ocid
  namespace      = local.namespace
  name           = var.bucket_name != "" ? var.bucket_name : "${var.name_prefix}-dev-scripts"
  access_type    = "NoPublicAccess"
}

data "oci_identity_compartment" "target" {
  id = var.compartment_ocid
}

resource "oci_objectstorage_object" "setup" {
  bucket    = local.bucket
  namespace = local.namespace
  object    = local.object_name
  content = templatefile("${path.module}/developer-setup.sh.tftpl", {
    application_name = oci_functions_application.function.display_name
    region           = var.region
    region_key       = var.region_key
    realm_domain     = local.realm_domain
    tenancy_name     = var.tenancy_name
    namespace        = local.namespace
    compartment_id   = var.compartment_ocid
    compartment_name = data.oci_identity_compartment.target.name
    repository_name  = var.name_prefix
    function_name    = var.function_name
    application_id   = oci_functions_application.function.id
    function_id      = var.enable_function_deployment ? oci_functions_function.function[0].id : ""
    identity_domain  = var.developer_identity_domain
    user_name        = var.developer_user_name
    oci_profile      = var.developer_oci_profile
    repository_url   = oci_devops_repository.function.http_url
  })
  lifecycle {
    precondition {
      condition     = var.bucket_choice == "Define" || var.existing_bucket_name != ""
      error_message = "Enter an existing bucket name when bucket_choice is Select."
    }
  }
}

resource "oci_objectstorage_preauthrequest" "setup" {
  namespace    = local.namespace
  bucket       = local.bucket
  object_name  = oci_objectstorage_object.setup.object
  name         = "${var.name_prefix}-developer-setup-read"
  access_type  = "ObjectRead"
  time_expires = var.par_expiration
}
