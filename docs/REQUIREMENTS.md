# Requirements

Build a Terraform stack for use with the OCI Resource Manager that builds a Functions application, OCI DevOps Functions Project, a hosted code repository, OCIR repository, build and deployment pipelines, and developer scripts to initialize local development environments and automate the process of pushing code into the CI/CD pipelines. 

## schema.yaml File

The Terraform Script will include a schema.yaml file to capture any required variables. Wherever possible, native lookups will be used in place of text boxes for OCID values. In cases where native lookups are not available, directions below the text box will describe where to obtain the required OCID.

Any prerequisite required resources will use Select or Define options in the schema.yaml so that the user implementing the stack may select existing resources or have the stack build out those resources using information provided by the user.

## Dev Setup Scripts

The terraform stack will build developer scripts to inititialize and support local development environments on developers' machines. The script will be stored in an Object Storage bucket, either selected or defined by the stack user. The stack will implement a pre-authenticated request for the script objects so that this can be given to users to download the scripts.

The dev setup scripts will use the [DEV_SETUP.md](.\DEV_SETUP.md) as the basis for defining the scripts. Environment variables identified in the DEV_SETUP.md file will be explicitly set in the script using values derived from the results of the terraform apply function and the OCI environment in which the code is to be deployed. Scripts should avoid using any code basis, or language not explicitly indicated in the DEV_SETUP.md file (i.e., don't use complicated python when explicitly setting permanent environment variables and running simple commands will accomplish the task).

## Simplicity

The terraform stack and resulting development scripts should be easy to read by most users familiar with Terraform and shell scripting.

## Repeatability

The terraform script should be reusable in multiple environments. The dev scripts built from the terraform apply need only be capable of being run on local machines with OCI CLI connections to the OCI tenancy in which they were built.

## IAM Permissions

Any permissions required to run the Terraform stack need to be in place before it is used. Documentation of these permission policies should be included in this project. Any permissions needed so the explicitly listed resources can function should be built by the terraform apply if possible. For example, any Dynamic Groups needed to define the function instances or allow the functions to act as resource principals would be created by the terraform stack.