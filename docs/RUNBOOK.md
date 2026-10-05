# Runbook

## 1. Prepare the stack

1. Review [PREREQUISITES.md](PREREQUISITES.md) and arrange the listed IAM policies before creating the stack.
2. Package the root Terraform files, `schema.yaml`, `README.md`, and `developer-setup.sh.tftpl` as the Resource Manager configuration. Keep `build_spec.yaml` for the hosted source repository too. Do not include `.terraform` or state files.
3. Create a Resource Manager stack from the package. For the network and bucket, check **Select an existing** to reveal existing-resource inputs or leave the checkbox unchecked to define new resources. Enter the destination, setup ZIP link lifetime in days (30 by default), and function settings in the schema form. Terraform looks up the tenancy name and region key. Leave **Enable Function and deployment stage** off.
4. Run a plan, review the resource names and IAM policy statements, then run the first apply. Record the `repository_url`, `build_pipeline_id`, `deploy_pipeline_id`, `container_image`, and sensitive `developer_setup_zip_url` outputs. The deployment pipeline exists now but has no stage yet.

For local Terraform, use `terraform init`, set the same variables with a local `.tfvars` file or environment variables, run `terraform plan -out=stack.tfplan`, and apply the reviewed plan with `terraform apply stack.tfplan`. Do not commit `.tfvars`, plan, or state files if they contain environment details.

## 2. Put Function source in the hosted repository

1. Create or obtain Function source with a Dockerfile that builds a valid Fn-compatible Function image. Place this repository's `build_spec.yaml` at the root alongside the Dockerfile.
2. Clone the `repository_url` from the first apply, add the source, commit to `main`, and push. The OCI DevOps trigger starts the build automatically. The generated setup script's `push` command runs `git push origin main` when the remote is named `origin`.
3. In **Developer Services → DevOps → Projects → Build Pipelines**, inspect the build run. Confirm the managed build produced `function-image` and the deliver stage placed `${name_prefix}/${function_name}:latest` in OCIR. Resolve build or Dockerfile errors before continuing.

## 3. Enable Function deployment

1. In the same Resource Manager stack, change only `enable_function_deployment` to `true`; retain all other values. Run and review a second plan, then apply.
2. Confirm the Function, Function deployment environment, deployment stage, and build pipeline trigger-deployment stage exist. The Function is initialized from the already-delivered `:latest` image.
3. Make a small application commit and push to `main`. Confirm the build and deliver stages succeed, then confirm the deployment pipeline updates the Function. Check the Function's image digest in the Console or OCI CLI.

## 4. Developer setup and everyday use

1. Retrieve the sensitive `developer_setup_zip_url` from Resource Manager outputs and use it to download the ZIP. Treat the PAR URL as a credential until it expires.
2. Extract the ZIP and follow its `README.md`. Each developer supplies their own full OCIR login username, OCI CLI profile name, and auth token to `developer-setup.sh setup`; none is embedded in the ZIP.
3. Work in the hosted repository and run `bash /path/to/developer-setup.sh push` from its root to push `main`. This starts the CI/CD pipeline. `bash /path/to/developer-setup.sh local-build '<oci-cli-profile>'` is available for the DEV_SETUP.md local Fn build/push workflow; after the second apply it also updates the Function image directly, so prefer `push` for the normal controlled pipeline.
4. Each apply calculates the PAR expiry from its apply time plus `par_expiration_days`; a subsequent apply may replace the PAR and change its sensitive URL. Redistribute the current URL after applying, especially when renewing an expired link.

## Operations and recovery

* If the first build fails, inspect its managed build logs and confirm `build_spec.yaml` and the Dockerfile are at the repository root. Confirm the pipeline dynamic-group policy has propagated and OCIR delivery permissions are in place.
* If the second apply fails while creating the Function, verify the exact `container_image` path and `:latest` tag exist in OCIR, and that the image is a valid OCI Function image in the same region. Leave `enable_function_deployment=false` until the image is ready, then retry.
* If deployment fails, check the deployment run and the Function environment's Function OCID. Verify the pipeline dynamic group can manage Functions and read OCIR in the compartment.
* To roll back, use a previously delivered image tag or digest in the deployment artifact and start a deployment run; do not assume `latest` still points to the old build. Preserve a known-good image before overwriting `latest`.
* Before destroy, stop pushes and pipeline runs. A bucket or OCIR repository containing objects/images may require emptying by an administrator according to OCI deletion behavior. Destroying the stack revokes the PAR and removes the Function and pipelines.
