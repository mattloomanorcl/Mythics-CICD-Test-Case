# Developer setup

Download the developer setup ZIP using the `developer_setup_zip_url` supplied by the stack owner. Treat that link as a credential until it expires. Extract the ZIP; it contains this README and `developer-setup.sh`.

## Before you start

Install Bash, Docker, Fn CLI, OCI CLI, and Git. Configure the OCI CLI profile selected for this stack on your computer. Obtain an OCI auth token for your own user; the token must belong to the same user you use for the OCIR login.

## Set up your Fn context and OCIR login

Run the script with your **full OCIR login username** and your auth token:

```bash
bash developer-setup.sh setup '<tenancy-namespace>/<identity-domain>/<username>' '<auth-token>'
```

For a native OCI user without an identity domain, use `<tenancy-namespace>/<username>`. Find the tenancy namespace in the OCI Console under Tenancy Information. Use the domain and username shown in your OCI profile for an identity domain user. The script does not contain a user's login name or auth token.

To avoid putting the token in a shell command, pass `-` as the second argument and enter the token at the prompt:

```bash
bash developer-setup.sh setup '<tenancy-namespace>/<identity-domain>/<username>' -
```

The script logs in to OCIR and creates or selects the Fn context for this stack. Run `setup` once per development environment or again when you need to refresh the Docker login.

## Work with the source repository

Clone the `repository_url` supplied by the stack owner. From the repository root, run:

```bash
bash /path/to/developer-setup.sh push
```

This pushes `main` to the hosted repository and starts the managed CI/CD pipeline. After the first image build and the stack's second apply, `local-build` is also available for the local Fn build and push workflow:

```bash
bash /path/to/developer-setup.sh local-build
```

The script uses the OCI CLI profile configured in the stack. `local-build` can update the deployed Function image directly, so use `push` for the normal managed pipeline.
