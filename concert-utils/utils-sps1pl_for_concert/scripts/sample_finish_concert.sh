#!/usr/bin/env bash
MY_NAME="[finish_concert.sh]"

##
# Note: Files in the directory ${CONCERT_TEMPLATES_PATH} can include
# manual settings.  Examples are application version, component version, etc.
# deployment automation scripts do not need those values.
##

##
# Pipeline settings, each of which can be obtained by
#   $(get_env <name> <default>)
#   where <default> is used if setting <name> does not exist.
#   For example, (get_env concert-version 0)
#
#   concert-apikey: [Required, secure setting] # pragma: allowlist secret
#   concert-if-cos: [Optional] 0 means skipping uploading Concert files to COS/S3
#   concert-toolkit-image: [Required] A "public" container image reference
#   concert-version: [Required] 0 means skipping Concert scripts
#   target-environment: [Required] E.g., "qa", "stage", "prod", etc.
##

##
# Pipeline export variables set before the custom "finish" stage:
#
#   ${APP_REPO}: URL of the code repo in use
#   ${APP_REPO_NAME}: Code repo name to the pipeline
#   ${BUILD_NUMBER}: Pipeline build number
#   ${PIPELINE_CONFIG_REPO_PATH}: Relative path of config repo in ${WORKSPACE}
#   ${WORKSPACE}: Ephemeral file-sharing space for pipeline scritps & containers
##

clone_path=${WORKSPACE}/${PIPELINE_CONFIG_REPO_PATH}
concert_path=${clone_path}/scripts/concert

##
# Set path aliases as export variables
##

# ${CONCERT_DATA_PATH} is RW for Concert Toolkit image container 
#
export CONCERT_DATA_PATH=${concert_path}/data

# ${CONCERT_HELPERS_PATH} includes Concert Toolkit utility scripts
#
# Note: GHE repo URL of the Concert Utils is:
#   https://github.ibm.com/roja/concert-utils
#
export CONCERT_HELPERS_PATH=${concert_path}/helpers/$(get_env concert-version "1.0.1")

# ${CONCERT_SCRIPTS_PATH} includes Concert automation scripts
#
# Note: Extending the "1PL Core" with the Concert support scripts
#   in this path are under development.  After the capabilities
#   are provided by the extended 1PL, this path will not be needed. 
#
export CONCERT_SCRIPTS_PATH=${concert_path}/scripts

# ${CONCERT_TEMPLATES_PATH} includes templates for generating Concert files
#
# Note: Advanced DevSecOps developers can customize the set of templates,
#   and use ${CONCERT_HELPERS_PATH}/helpers scripts
#   to generate and upload Concert-supported files.
#   Samples are available from the GHE repo:
#     https://github.ibm.com/roja/concert-sample
#
export CONCERT_TEMPLATES_PATH=${concert_path}/templates/$(get_env concert-version "1.0.1")

##
# Set additional configuration settings for Concert file generation
#
# Note: Previous OnePipeline CI pipeline stages have finished, among other tasks:
#  (1) CycloneDX SBOM generation (from source code)
#  (2) CVE-based vulnerability discoveries
#  (3) JSON-formated "image inventory", including envidence
#      for the built image and the code repository in use
#  (4) Acceptance testing for a deployment in the "qa" environment  
#
# In terms of contents dependencies, recommended file generation sequence
# in Concert-supported formats is:
#   "cyclonedx" > "vulnerability" > "build" > "deploy" > "application-def"
#
# Necessary manual configuration settings (like the business unit data
# of an "application-def" file) are done by changing the Concert config.sh file.
##

##
# Set export variables for running Concert Toolkit image
#
# Note: Use root uid to run the image in DevSecOps DinD
#
export CONCERT_TOOLKIT_IMAGE=$(get_env concert-toolkit-image "icr.io/cpopen/ibm-concert-toolkit:latest")
export CONTAINER_COMMAND="docker run"
export OPTIONS="-i --rm -u 0"

##
# Set export variables for the Concert API service endpoint
#
export CONCERT_URL=$(get_env concert-url)
if [[ -z ${CONCERT_URL} ]]; then
  echo "*** ${MY_NAME}: Variable not set: ${CONCERT_URL}" 
  exit 1
fi

export INSTANCE_ID=$(get_env concert-instance-id "0000-0000-0000-0000")

export API_KEY=$(get_env concert-api-key)
if [[ -z ${API_KEY} ]]; then
  echo "*** ${MY_NAME}: Variable not set: ${API_KEY}" 
  exit 1
fi

##
# Selectively run Concert file generation & upload scripts in sequence
##

# Upload file type: cyclonedx
#
# Note: This script leverages the CycloneDX SBOM created 
#   by 1PL CRA from the source code. BOM-Link of the SBOM
#   is included in the "build" inventory SBOM for Concert v1.0.2+.
#
if [[ "ci" == ${PIPELINE_NAMESPACE} ]]; then
  ${CONCERT_SCRIPTS_PATH}/file_cyclonedx.sh
  # ${CONCERT_SCRIPTS_PATH}/file_cyclonedx.sh ${custome.yaml.template}
  # ${CONCERT_SCRIPTS_PATH}/file_cyclonedx.sh ${custome.json}
fi

# Upload file type: vulnerability
#
# Note: This script leverages the "evidence summary" created by 1PL.
#   CSV-formatted CVE is generated from the JSON-formatted summary.
#
if [[ "ci" == ${PIPELINE_NAMESPACE} ]] \
    || [[ "cc" == ${PIPELINE_NAMESPACE} ]]; then
  ${CONCERT_SCRIPTS_PATH}/file_vulnerability.sh
  # ${CONCERT_SCRIPTS_PATH}/file_vulnerability.sh ${custome.yaml.template}
  # ${CONCERT_SCRIPTS_PATH}/file_vulnerability.sh ${custome.json}
fi

# Upload file type: build
#
# Note: This script leverages 1PL "inventory" repo, which contains
# one JSON-formatted "image inventory file" for each built image
# of a specific "inventory" repo commit.
#
if [[ "ci" == ${PIPELINE_NAMESPACE} ]]; then
  ${CONCERT_SCRIPTS_PATH}/file_build.sh
  # ${CONCERT_SCRIPTS_PATH}/file_build.sh ${custome.yaml.template}
  # ${CONCERT_SCRIPTS_PATH}/file_build.sh ${custome.json}
fi

# Upload file type: deploy
#
# Note: This script takes a "1PL artifact" of type "deploy" as input.
#   In support of Concert Application 360 Insights, contents of
#   the "1PL artifacts" compliment DevSecOps data with continuous
#   post-deployment application monitoring in business terms.
#
if [[ "ci" == ${PIPELINE_NAMESPACE} ]] \
    || [[ "cd" == ${PIPELINE_NAMESPACE} ]]; then
  ${CONCERT_SCRIPTS_PATH}/file_deploy_${PIPELINE_NAMESPACE}.sh
  # ${CONCERT_SCRIPTS_PATH}/file_deploy_${PIPELINE_NAMESPACE}.sh ${custome.yaml.template}
  # ${CONCERT_SCRIPTS_PATH}/file_deploy_${PIPELINE_NAMESPACE}.sh ${custome.json}
fi

# Upload file type: application-def
#
# Note: It is recommended to create Concert application definition SBOMs
# via the Concert console in terms of business organization info,
# constituent microservice components of the business application,
# business application criticality, deployment environments, etc.
#
# The application-def template in use exemplifies how a one-component
# Concert application definition SBOM can be automatically generated
# for a container-based microservice.  The microservice can be included
# in other Concert (multi-component) application definition SBOMs
# as a shared service for those composed applications.
#
if [[ "ci" == ${PIPELINE_NAMESPACE} ]]; then
  ${CONCERT_SCRIPTS_PATH}/file_application-def.sh
  # ${CONCERT_SCRIPTS_PATH}/file_application-def.sh ${custome.yaml.template}
  # ${CONCERT_SCRIPTS_PATH}/file_application-def.sh ${custome.json}
fi
