# OCI Functions CI/CD Terraform stack

This project provisions an Oracle Cloud Infrastructure (OCI) development and delivery environment for one Function. It creates the cloud resources and a developer setup download; the Function's application source code lives in the OCI DevOps hosted repository created by the stack.

The stack is designed for OCI Resource Manager. Its `schema.yaml` presents the inputs in the Resource Manager form, including choices to use an existing network or bucket or create new ones.

## What it creates

- An OCI Functions application and a private OCIR repository for its image.
- An OCI DevOps project with a hosted Git repository, build and deployment pipelines, and a trigger for pushes to `main`.
- A private subnet and supporting network resources, unless an existing subnet is selected.
- An Object Storage bucket, unless one is selected, containing a generated ZIP with `developer-setup.sh` and its own README. A read-only pre-authenticated request (PAR) provides a download link.
- A Notifications topic and IAM resources needed by the pipelines. The Function and its deployment stages are added after the first image build.

The build pipeline runs `build_spec.yaml` from the hosted source repository, builds the Function image with Podman, and delivers it to OCIR. After deployment is enabled, later builds trigger the deployment pipeline.

## Before deploying

Review [prerequisites](docs/PREREQUISITES.md) for OCI permissions, service availability, and developer tools. The Resource Manager principal needs permission to create the resources and IAM policies before the first apply. The hosted repository also needs Function source, a Dockerfile that builds an OCI Functions image, and this project's `build_spec.yaml` before the first build can run.

Use a unique lowercase `name_prefix` for each environment. The setup ZIP link expires after `par_expiration_days` (30 by default).

## Deploy with Resource Manager

1. Create a Resource Manager stack from [the packaged Terraform configuration](dist/FunctionsSetup-RMStack.zip). The package contains the Terraform files, `schema.yaml`, the setup-script template, and the developer README used to generate the download ZIP.
2. Set the target region, compartment, and name prefix. Choose an existing network or bucket if appropriate, or leave those choices unchecked to create them. Leave **Enable Function and deployment stage** unchecked. Review the plan and run the first apply.
3. Use the `repository_url` output to clone the new hosted repository. Add your Function source, Dockerfile, and `build_spec.yaml`, then push to `main`. Wait for the build to deliver the first `:latest` image to OCIR.
4. Set `enable_function_deployment` to `true` in the same stack. Review and apply again to create the Function and connect the deployment pipeline. Later pushes to `main` build and deploy the Function.

The two applies are required because OCI Functions needs an image in OCIR when the Function is created. See the [runbook](docs/RUNBOOK.md) for the full sequence and recovery guidance.

## Developer setup

After the first apply, the sensitive `developer_setup_zip_url` output downloads a ZIP containing `developer-setup.sh` and a developer-facing `README.md`. Share that link only with intended developers. Each developer supplies their own OCIR login username, auth token, and OCI CLI profile when running the script; those credentials are not embedded in the ZIP. The developer instructions used to build that ZIP are in [docs/DEVELOPER_README.md](docs/DEVELOPER_README.md).

For normal development, the script's `push` command sends the current `main` branch to the hosted repository and starts the managed pipeline. The optional `local-build` command follows the [local Fn workflow](docs/DEV_SETUP.md) and can update the Function directly after deployment is enabled.

## Repository guide

| Path | Purpose |
| --- | --- |
| `schema.yaml`, `variables.tf` | Resource Manager form and Terraform inputs |
| `main.tf`, `network.tf`, `iam.tf`, `storage.tf` | OCI resources, network, IAM, and developer ZIP upload |
| `developer-setup.sh.tftpl`, `docs/DEVELOPER_README.md` | Files used to generate the developer download ZIP |
| `build_spec.yaml` | Build specification to place in the hosted Function source repository |
| `docs/ARCHITECTURE.md`, `docs/RUNBOOK.md` | Resource design and deployment steps |

The PAR URL may change after an apply; use the current `developer_setup_zip_url` output when sharing the download.
