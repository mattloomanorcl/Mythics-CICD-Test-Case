# Prerequisites for a successful apply

## OCI and Resource Manager

* An OCI tenancy, target compartment, and region with Functions, DevOps, Object Storage, Notifications, and Container Registry available, plus sufficient service limits and quota.
* The Resource Manager stack or Terraform principal must already be able to manage the target compartment's VCNs, subnets, service gateways, Functions applications and functions, DevOps projects, repositories, pipelines, stages, triggers, deploy artifacts and environments, OCIR repositories, Object Storage buckets, objects and PARs, and Notifications topics. It also needs to read the tenancy name, region list, tenancy namespace, and compartment details.
* A tenancy administrator must grant the apply principal permission to create dynamic groups in the tenancy and IAM policies in the target compartment. These permissions cannot be supplied by the same stack before its first apply. Example policies for the principal's group, adjusted to your tenancy's group and compartment names, are:

  ```text
  Allow group <apply-group> to manage dynamic-groups in tenancy
  Allow group <apply-group> to manage policies in compartment <target-compartment>
  Allow group <apply-group> to manage virtual-network-family in compartment <target-compartment>
  Allow group <apply-group> to manage functions-family in compartment <target-compartment>
  Allow group <apply-group> to manage devops-family in compartment <target-compartment>
  Allow group <apply-group> to manage repos in compartment <target-compartment>
  Allow group <apply-group> to manage buckets in compartment <target-compartment>
  Allow group <apply-group> to manage objects in compartment <target-compartment>
  Allow group <apply-group> to manage ons-topics in compartment <target-compartment>
  ```

  A tenancy administrator may need to create or adjust these policies at a parent compartment if the Resource Manager principal cannot see the target compartment. Verify your tenancy's group syntax, identity domain, and policy placement with your IAM administrator.
* Use a unique lowercase `name_prefix` for each environment. Names of dynamic groups are tenancy-wide; bucket and OCIR names must also avoid collisions.
* Set `par_expiration_days` to the desired developer setup ZIP link lifetime (30 days by default). Set `enable_function_deployment=false` for the first apply.

## Select options

* If the existing function network checkbox is checked (`network_choice=true`), choose an existing private regional subnet in the target compartment. Its route table must allow access to OCI services, including OCIR and Functions, through a service gateway; any other destinations needed by the Function need suitable routes and security rules. The schema's VCN choice narrows the native subnet selector. Leave the checkbox unchecked (`false`) to define a new VCN and subnet.
* If the existing developer script bucket checkbox is checked (`bucket_choice=true`), enter an existing bucket name in the target compartment and tenancy namespace. Resource Manager has no native bucket-name selector in this schema, so obtain the name from **Storage → Buckets** in the OCI Console. The apply principal must be allowed to write the setup object and create a PAR on the bucket. Leave the checkbox unchecked (`false`) to define a new bucket.

## Developer and source repository

* The developer needs Git, Docker, Fn CLI, OCI CLI configured for the selected profile, and a valid OCI auth token for OCIR. The developer's IAM access must permit reading and pushing the hosted DevOps repository, pushing to the private OCIR repository for optional local builds, and updating the Function if using `local-build` after bootstrap.
* The source pushed to `main` must include `build_spec.yaml` and a Dockerfile that builds a valid OCI Functions image. Include application code and any runtime dependencies. For the optional local Fn workflow, also include `func.yaml` with a function name matching `function_name` and a version. The managed build uses `podman build` from the repository root. The repository is empty immediately after Terraform creates it.
* The generated script uses Bash. On Windows, run it in a compatible Bash environment with Docker, Fn, OCI CLI, and Git available there.

Oracle references: [DevOps IAM policies](https://docs.oracle.com/en-us/iaas/Content/devops/using/devops_iampolicies.htm), [build specifications](https://docs.oracle.com/en-us/iaas/Content/devops/using/build_specs.htm), [Resource Manager schema](https://docs.oracle.com/en-us/iaas/Content/ResourceManager/Concepts/terraformconfigresourcemanager_topic-schema.htm).
