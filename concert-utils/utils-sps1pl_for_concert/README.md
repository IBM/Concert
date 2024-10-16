# IBM SPS/1PL DevSecOps Extensions for Concert

IBM SPS (Secure Pipeline Service) OnePipeline (1PL) provides an opinionated GitOps-based ___DevSecOps implementation framework___ with, among other types of pipelines, Continuous Integration (CI), Continuous Deployment (CD), and Continuous Compliance (CC) pipelines. Successful execution of a specific CI pipelinerun produces an ___SPS/1PL inventory___ repo commit that enables a downstream CD pipelinerun to deploy the images built by the CI pipelinerun to a deployment environment. Successful execution of a specific CD pipelinerun also produces an ___SPS/1PL inventory___ repo commit that enables a downstream CC pipelinerun to continuously perform scheduled vulnerablity and compliance analyses of the deployed images.

Per the principal of separation of concerns, Concert extension scripts should run in the `final` stage of a CI/CD/CC pipeline.
This approach also minimizes the necessary information-gathering changes to existing pipelines.  In the `scripts` sub-directory, there are two different sample scripts that exemplify how a `deploy.sh` in use can be extended with an information-gathering `if` statement at the end such that ConcertDef `deploy` inventory SBOM can be generated and uploaded to Concert automatically by the application-neutral Concert scripts.  The approach to extending an existing pipeline for Concert data generation and uploading is generic and not specific to SPS/1PL.  For those non-SPS/1PL pipelines, the utility scripts exemplify how such extensions can be delivered with minimum impact to existing pipelines.

Considering the common file structure of an SPS/1PL-enabled code repo, all Concert-specific artifacts (including scripts and templates) are expected to be in the `./scripts/concert` directory by default.  Application specific settings for the Concert extension can be configured by changing the file `./scripts/finish_concert.sh`, which must be invoked at the of the `finish` stage defined in the file `./.pipeline-config.yaml`. File `sample_pipeline-config.yaml` shows how the custome `final` stage can be defined in the SPS/1PL configuration file `.pipeline-config.yaml`.

In the sub-directory `scripts/concert/scripts`, there are six files.  They are application neutral and have been tested extensively using three very different sets of code repos (used by CI & CC pipelines) as well as deployment repos (used by CD pipelines).  Two scripts are used to generate and upload ConcertDef `deploy` inventory SBOMs because the `deploy.sh` in CI and CD have different image deployment requirements. All the scripts are being integrated into an extended `1PL Core` for Concert, and should be read-only to the exploiters in the meantime.

Sub-directory `scripts/concert/data` is used to exchange input/output data with the Concert Toolkit image container in use.
Sub-directories `scripts/concert/helpers` and `scripts/concert/templates` are organized by Concert version.
Version 1.0.1 `helpers` scripts are replica of the files in the `./helpers` directory of this repo.
Version 1.0.1 `templates` files are copied over from the `./templates` direcotry of the
[concert-sample](https://github.ibm.com/roja/concert-sample) repo.  Custome ConcertDef template files (formated in YAML or JSON) can be specifed when running the scripts in `scripts/concert/scripts`, as shown by the comments in `sample_finish_concert.sh` in this directory.
Version 1.0.2 files will be added soon after Concert 1.0.2 is released.

The file `concert_sps1pl_utils-YYYYMMDD.pdf`is a PPT presentation on the pipeline extension scripts for Concert.
