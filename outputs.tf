output "application_id" { value = oci_functions_application.function.id }
output "function_id" { value = var.enable_function_deployment ? oci_functions_function.function[0].id : null }
output "project_id" { value = oci_devops_project.function.id }
output "repository_url" { value = oci_devops_repository.function.http_url }
output "build_pipeline_id" { value = oci_devops_build_pipeline.function.id }
output "deploy_pipeline_id" { value = oci_devops_deploy_pipeline.function.id }
output "container_image" { value = "${local.registry}:latest" }
output "function_dynamic_group_name" {
  value = var.enable_function_deployment ? oci_identity_dynamic_group.function[0].name : null
}
output "developer_script_url" {
  value     = "https://objectstorage.${var.region}.${local.realm_domain}${oci_objectstorage_preauthrequest.setup.access_uri}"
  sensitive = true
}
