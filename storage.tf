resource "oci_objectstorage_bucket" "scripts" {
  count          = var.bucket_choice ? 0 : 1
  compartment_id = var.compartment_ocid
  namespace      = local.namespace
  name           = var.bucket_name != "" ? var.bucket_name : "${var.name_prefix}-dev-scripts"
  access_type    = "NoPublicAccess"
}

data "oci_identity_compartment" "target" {
  id = var.compartment_ocid
}

resource "archive_file" "developer_setup" {
  type             = "zip"
  output_path      = abspath("${path.root}/${local.object_name}")
  output_file_mode = "0644"

  source {
    filename = "developer-setup.sh"
    content = templatefile("${path.module}/developer-setup.sh.tftpl", {
      application_name = oci_functions_application.function.display_name
      region           = var.region
      region_key       = local.region_key
      realm_domain     = local.realm_domain
      tenancy_name     = data.oci_identity_tenancy.current.name
      namespace        = local.namespace
      compartment_id   = var.compartment_ocid
      compartment_name = data.oci_identity_compartment.target.name
      repository_name  = var.name_prefix
      function_name    = var.function_name
      application_id   = oci_functions_application.function.id
      function_id      = var.enable_function_deployment ? oci_functions_function.function[0].id : ""
      repository_url   = oci_devops_repository.function.http_url
    })
  }

  source {
    filename = "README.md"
    content  = file("${path.module}/README.md")
  }
}

resource "oci_objectstorage_object" "setup" {
  bucket              = local.bucket
  namespace           = local.namespace
  object              = local.object_name
  source              = archive_file.developer_setup.output_path
  content_type        = "application/zip"
  content_disposition = "attachment; filename=\"${local.object_name}\""
  metadata = {
    sha256 = archive_file.developer_setup.output_sha256
  }
  lifecycle {
    precondition {
      condition     = !var.bucket_choice || var.existing_bucket_name != ""
      error_message = "Enter an existing bucket name when the existing developer script bucket checkbox is checked."
    }
  }
}

resource "oci_objectstorage_preauthrequest" "setup" {
  namespace    = local.namespace
  bucket       = local.bucket
  object_name  = oci_objectstorage_object.setup.object
  name         = "${var.name_prefix}-developer-setup-read"
  access_type  = "ObjectRead"
  time_expires = timeadd(timestamp(), "${var.par_expiration_days * 24}h")
}
