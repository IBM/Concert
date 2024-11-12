# concert-sample

This code was tested on Linux and macOS systems.

This example contains sample scripts to create z/OS Application and build SBOMs from a CI/CD pipeline to integrate with IBM Concert.  During this flow, the CI/CD pipeline generates and sends the data that Concert needs.

## Pre-requisites

1. `docker` running on your workstation (or `podman` configured with docker emulation).

## Setup instructions

1. Go to the `scripts` directory and run the `setup_z` script:

   ```bash
   ./setup_z.sh
   ```

1. Go to the `concert_data` directory and update the `demo_build_envs_z.variables` file by entering the proper values for your target environment. The variables in the `demo_build_envs_z.variables` file control the behavior of the scripts in this repo. The following are *typical* variables you may want to update in this file. A sample is provided at 'demo_build_envs_z_sample.varibles':

* `CONCERT_URL` - Your Concert URL with the suffix `/ibm/concert` (e.g., `https://concert-concert-instance.apps.o2-160435.cp.fyre.ibm.com/ibm/concert`).
* `INSTANCE_ID` - For non-SaaS deployments of Concert, use `0000-0000-0000-0000`
* `API_KEY` - Your Concert API key value. Use either `C_API_KEY <apikey>` or `ZenApiKey <apikey>` depending on where Concert is hosted (where `<apikey>` is your API key value). See [Generating and using an API key](https://www.ibm.com/docs/en/concert?topic=started-generating-using-api-key) for instructions to generate an API key.
* `APP_NAME` - Name of your application
* `APP_VERSION` - Version of your application
* `COMPONENT_NAME` - Your application component name
* `COMPONENT_VERSION` - Version of your application component
* `COMPONENT_SOURCECODE_REPO_NAME` - Name of the source code repository for your application component
* `COMPONENT_SOURCECODE_REPO_URL` - URL for the source code repository for your application component
* `COMPONENT_LIBRARY_NAME` - Archive name for your application component that is published to the artifact repository
* `ENVIRONMENT_NAME_1` - Name of the environment where your application is hosted. The SBOMs will pertain to any builds that are intended for this environment

## Running the example 

1. Go to the `scripts` folder.
1. Run the `application_definition_z.sh` script. You only need to run this script once *or* when updates to the application definition are required. E.g. This could be at every major release. This provides Concert with initial details of your application and of the forthcoming data to construct the Application inventory and Arena view. This generates an Application `ConcertDef` SBOM (e.g., application name, application component repository, application library).  

   ```bash
   ./application_definition_z.sh
   ```

1. Run the `simulate_ci_pipeline_z.sh` script. This script is to be integrated into a CICD pipeline after the packaging step by IBM DBB(https://github.com/IBM/dbb) for a z/OS application. This step generates of a Build `ConcertDef` SBOM file from the output of the DBB packaging step and pushes it into Concert.

   ```bash
   ./simulate_ci_pipeline_z.sh
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

Finally, for your reference, the `OPTIONS` environment variable defined in the `concert_data/demo_build_envs_z.variables` file is used when `concert-utils` runs the `ibm-concert-toolkit` container.