data "oci_objectstorage_namespace" "tenancy" {
  compartment_id = var.tenancy_ocid
}

data "oci_identity_tenancy" "current" {
  tenancy_id = var.tenancy_ocid
}

data "oci_identity_regions" "all" {}

locals {
  # The hosted repository URL is returned by OCI in the same realm as the
  # stack, for example devops.scmservice.<region>.oci.oraclecloud.com.
  repository_host = split("/", oci_devops_repository.function.http_url)[2]
  realm_domain    = split(".oci.", local.repository_host)[1]
  namespace       = data.oci_objectstorage_namespace.tenancy.namespace
  region_key      = one([for region in data.oci_identity_regions.all.regions : region.key if region.name == var.region])
  registry        = "ocir.${var.region}.oci.${local.realm_domain}/${local.namespace}/${var.name_prefix}/${var.function_name}"
  bucket          = var.bucket_choice ? var.existing_bucket_name : oci_objectstorage_bucket.scripts[0].name
  object_name     = "${var.name_prefix}-developer-setup.zip"
}

resource "oci_functions_application" "function" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.name_prefix}-functions"
  subnet_ids     = [local.subnet_id]
  lifecycle {
    precondition {
      condition     = !var.network_choice || var.existing_subnet_ocid != ""
      error_message = "Select an existing subnet OCID when the existing function network checkbox is checked."
    }
  }
}

resource "oci_artifacts_container_repository" "function" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.name_prefix}/${var.function_name}"
  is_public      = false
}

resource "oci_devops_project" "function" {
  compartment_id = var.compartment_ocid
  name           = "${var.name_prefix}-functions"
  notification_config {
    topic_id = oci_ons_notification_topic.project.id
  }
}

resource "oci_ons_notification_topic" "project" {
  compartment_id = var.compartment_ocid
  name           = "${var.name_prefix}-devops"
}

resource "oci_devops_repository" "function" {
  project_id      = oci_devops_project.function.id
  name            = "${var.name_prefix}-source"
  repository_type = "HOSTED"
  default_branch  = "main"
}

resource "oci_devops_build_pipeline" "function" {
  project_id   = oci_devops_project.function.id
  display_name = "${var.name_prefix}-build"
}

resource "oci_devops_deploy_artifact" "image" {
  project_id                 = oci_devops_project.function.id
  deploy_artifact_type       = "DOCKER_IMAGE"
  display_name               = "${var.name_prefix}-image"
  argument_substitution_mode = "NONE"
  deploy_artifact_source {
    deploy_artifact_source_type = "OCIR"
    image_uri                   = "${local.registry}:latest"
  }
}

resource "oci_devops_build_pipeline_stage" "build" {
  build_pipeline_id         = oci_devops_build_pipeline.function.id
  build_pipeline_stage_type = "BUILD"
  display_name              = "Build function image"
  image                     = "OL8_X86_64_STANDARD_10"
  build_spec_file           = "build_spec.yaml"
  primary_build_source      = "source"
  build_runner_shape_config {
    build_runner_type = "DEFAULT"
  }
  build_source_collection {
    items {
      name            = "source"
      connection_type = "DEVOPS_CODE_REPOSITORY"
      repository_id   = oci_devops_repository.function.id
      repository_url  = oci_devops_repository.function.http_url
      branch          = "main"
    }
  }
  build_pipeline_stage_predecessor_collection {
    items { id = oci_devops_build_pipeline.function.id }
  }
  depends_on = [oci_identity_policy.pipeline]
}

resource "oci_devops_build_pipeline_stage" "deliver" {
  build_pipeline_id         = oci_devops_build_pipeline.function.id
  build_pipeline_stage_type = "DELIVER_ARTIFACT"
  display_name              = "Deliver function image"
  deliver_artifact_collection {
    items {
      artifact_id   = oci_devops_deploy_artifact.image.id
      artifact_name = "function-image"
    }
  }
  build_pipeline_stage_predecessor_collection {
    items { id = oci_devops_build_pipeline_stage.build.id }
  }
}

resource "oci_devops_trigger" "main" {
  project_id     = oci_devops_project.function.id
  repository_id  = oci_devops_repository.function.id
  trigger_source = "DEVOPS_CODE_REPOSITORY"
  display_name   = "${var.name_prefix}-main-push"
  actions {
    type              = "TRIGGER_BUILD_PIPELINE"
    build_pipeline_id = oci_devops_build_pipeline.function.id
    filter {
      trigger_source = "DEVOPS_CODE_REPOSITORY"
      events         = ["PUSH"]
      include { head_ref = "main" }
    }
  }
}

# The first apply deliberately excludes these resources. The first build must
# deliver :latest before OCI Functions can create a function from that image.
resource "oci_functions_function" "function" {
  count          = var.enable_function_deployment ? 1 : 0
  application_id = oci_functions_application.function.id
  display_name   = var.function_name
  image          = "${local.registry}:latest"
  memory_in_mbs  = var.function_memory_mb
  depends_on     = [oci_artifacts_container_repository.function]
  lifecycle {
    ignore_changes = [image_digest]
  }
}

resource "oci_devops_deploy_environment" "function" {
  count                   = var.enable_function_deployment ? 1 : 0
  project_id              = oci_devops_project.function.id
  deploy_environment_type = "FUNCTION"
  function_id             = oci_functions_function.function[0].id
  display_name            = "${var.name_prefix}-function-environment"
}

resource "oci_devops_deploy_pipeline" "function" {
  project_id   = oci_devops_project.function.id
  display_name = "${var.name_prefix}-deploy"
}

resource "oci_devops_deploy_stage" "function" {
  count                           = var.enable_function_deployment ? 1 : 0
  deploy_pipeline_id              = oci_devops_deploy_pipeline.function.id
  deploy_stage_type               = "DEPLOY_FUNCTION"
  display_name                    = "Deploy function"
  function_deploy_environment_id  = oci_devops_deploy_environment.function[0].id
  docker_image_deploy_artifact_id = oci_devops_deploy_artifact.image.id
  deploy_stage_predecessor_collection {
    items { id = oci_devops_deploy_pipeline.function.id }
  }
  depends_on = [oci_identity_policy.pipeline]
}

resource "oci_devops_build_pipeline_stage" "deploy" {
  count                          = var.enable_function_deployment ? 1 : 0
  build_pipeline_id              = oci_devops_build_pipeline.function.id
  build_pipeline_stage_type      = "TRIGGER_DEPLOYMENT_PIPELINE"
  display_name                   = "Trigger deployment"
  deploy_pipeline_id             = oci_devops_deploy_pipeline.function.id
  is_pass_all_parameters_enabled = false
  build_pipeline_stage_predecessor_collection {
    items { id = oci_devops_build_pipeline_stage.deliver.id }
  }
  depends_on = [oci_devops_deploy_stage.function]
}
