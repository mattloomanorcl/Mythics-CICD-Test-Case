# Build Setup

Set local environment variables as are required for OCI Function development and deployment. Note the use of OCI CLI tool below for convenience. Static values may be defined otherwise.

``` bash
FN_OCIR_HOST="ocir.${FN_REGION}.oci.oracle${FN_ISGOV}cloud.com"

FN_OCIR_PATH="${TENANCY_NS}/${FN_OCIR}/${FN_IMAGE_NAME}"
FN_CONTEXT="$(echo "${FN_TENANCY_NAME}-${FN_REGION_KEY}-${FN_IMAGE_NAME}" | tr '[:upper:]' '[:lower:]')"
FN_COMP_ID="$(oci iam compartment list --compartment-id-in-subtree true --all --raw-output --query "data[?name==‘$FN_COMP_NAME'].id | [0]")"
```

Login to the OCI Registry service

``` bash
docker login "${FN_OCIR_HOST}" -u "${TENANCY_NS}/${OCI_DOMAIN_NAME}/${FN_USER_NAME}" -p $FN_TOKEN
```

# Initial function setup

This is only required once per development environment (e.g. developer laptop or centralized development system)

``` bash
fn create context "$FN_CONTEXT" --provider oracle
fn use context $FN_CONTEXT
fn update context oracle.compartment-id $FN_COMP_ID
fn update context api-url "https://functions.${FN_REGION}.oci.oracle${FN_ISGOV}cloud.com"
 
fn update context registry "${FN_OCIR_HOST}/${TENANCY_NS}/${FN_OCIR}"
fn update context oracle.profile $FN_SDK_PROFILE
```

# Build
Once the func.py code is ready, use the commands below to build then push the image to OCI Container Registry for use as a Function.

``` bash
fn use context $FN_CONTEXT
fn bump #increase version number
fn build
fn push
```

# Tag latest

Use this to add an additional tag latest so that the deployed OCI Function resource can be configured to use a consistent tag vs. an ever-increasing version number.

``` bash
BUILD_VER="$(docker images --format "{{.CreatedAt}} {{.Repository}} {{.Tag}}" | grep "${FN_OCIR_HOST}/${FN_OCIR_PATH}" | grep -v "latest" | sort -r | head -1 | awk '$6 != "latest" {print $6}')"; echo $BUILD_VER
IMAGE="${FN_OCIR_HOST}/${FN_OCIR_PATH}"; echo $IMAGE
docker tag "${IMAGE}:${BUILD_VER}" "${IMAGE}:latest"
docker push "${IMAGE}:latest"
printf 'Old digest: ' && oci fn function list --application-id $FN_APP_ID --display-name "$FN_IMAGE_NAME" --query 'data[0]."image-digest"' --raw-output
printf 'New digest: ' && oci fn function update --function-id $FN_FN_ID --image "${IMAGE}:latest" --query 'data."image-digest"' --raw-output
```