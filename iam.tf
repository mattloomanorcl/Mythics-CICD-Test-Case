resource "oci_identity_dynamic_group" "pipeline" {
  compartment_id = var.tenancy_ocid
  name           = "${replace(var.name_prefix, "-", "_")}_pipelines"
  description    = "Build and deployment pipelines for ${var.name_prefix}"
  matching_rule  = "Any {resource.id = '${oci_devops_build_pipeline.function.id}', resource.id = '${oci_devops_deploy_pipeline.function.id}'}"
}

resource "oci_identity_policy" "pipeline" {
  compartment_id = var.compartment_ocid
  name           = "${var.name_prefix}-pipeline-access"
  description    = "Permissions for DevOps build and Function deployment"
  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.pipeline.name} to manage repos in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group ${oci_identity_dynamic_group.pipeline.name} to manage devops-family in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group ${oci_identity_dynamic_group.pipeline.name} to manage functions-family in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group ${oci_identity_dynamic_group.pipeline.name} to use ons-topics in compartment id ${var.compartment_ocid}"
  ]
}

resource "oci_identity_dynamic_group" "function" {
  count          = var.enable_function_deployment ? 1 : 0
  compartment_id = var.tenancy_ocid
  name           = "${replace(var.name_prefix, "-", "_")}_functions"
  description    = "Function resource principal for ${var.name_prefix}"
  matching_rule  = "All {resource.id = '${oci_functions_function.function[0].id}'}"
}

# The function dynamic group has no service permissions by default. Add only
# the specific policies required by the function implementation.
