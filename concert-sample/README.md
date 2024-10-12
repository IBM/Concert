# concert-sample

This code was tested on a Linux system (our engineering team will test soon on a macOS system).

This example simulates a CI/CD pipeline and its integration with Concert. It emulates a CI/CD pipeline update, where the release of an application is pushed to the target environment. During this flow, the CI/CD pipeline generates and sends the data that Concert needs.

## Pre-requisites

1. `docker` running on your workstation (or `podman` configured with docker emulation).

## Setup instructions

1. Go to the `scripts` directory and run the `setup` script:

   ```bash
   ./setup.sh
   ```

1. Go to the `concert_data` directory and update the `demo_build_envs.variables` file accordingly by entering the proper values for your target environment. The variables in the `demo_build_envs.variables` file control the behavior of the scripts in this repo. The following are typical variables you may want to update:

* `CONCERT_URL` - Your Concert URL with the suffix `/ibm/concert` (e.g., `https://concert-concert-instance.apps.o2-160435.cp.fyre.ibm.com/ibm/concert`).
* `INSTANCE_ID` - For non-SaaS deployments of Concert, use `0000-0000-0000-0000`
* `API_KEY` - Your Concert API key value. Use either `C_API_KEY <apikey>` or `ZenApiKey <apikey>` depending on where Concert is hosted (where `<apikey>` is your API key value). See [Generating and using an API key](https://www.ibm.com/docs/en/concert?topic=started-generating-using-api-key) for instructions to generate an API key.
* `APP_NAME` - Name of your application
* `APP_VERSION` - Version of your application
* `COMPONENT_NAME` - Your application component name
* `ENVIRONMENT_NAME_1` - Name of the first environment where your application is hosted
* `ENVIRONMENT_NAME_2` - Name of the second environment where your application is hosted
* `ENVIRONMENT_NAME_3` - Name of the third environment where your application is hosted
* `IMAGE_NAME` - The image name for your application component
* `IMAGE_TAG` - The image tag for your application component

## Running the example 

1. Go to the `scripts` folder.
1. Run the `application_definition.sh` script. You only need to run this script once *or* when updates to the application definition are required. This provides Concert with initial details of your application and of the forthcoming data to construct the Application inventory and Arena view.

   ```bash
   ./application_definition.sh
   ```

1. Run the `simulate_ci_pipeline.sh` script. This simulates the generation of application assets (e.g., image, CycloneDX SBOM files, Concert Build SBOM file, etc.) to represent a commited version that can be released to any environment such as pre-production environments.

   ```bash
   ./simulate_ci_pipeline.sh
   ```

1. Run the `simulate_cd_pipeline.sh` script. This simulates the generation of application assets (e.g., image, CycloneDX SBOM files, Concert Build SBOM file, etc.) to represent a commited version that can be released to any environment such as pre-production environments.

   ```bash
   ./simulate_cd_pipeline.sh
   ```

## Notes

If you use `podman` instead of `docker`, please update the following line in the `concert_data/demo_build_envs.variables` file, from

```bash
export CONTAINER_COMMAND="docker run" 
```

to

```bash
export CONTAINER_COMMAND="podman run"
```

If you run into problems running the container due to missing options or other problems with user permissions, please update the following variable definition in the `concert_data/demo_build_envs.variables` file:

```bash
export OPTIONS="-it --rm -u $(id -u):$(id -g)" 
```
