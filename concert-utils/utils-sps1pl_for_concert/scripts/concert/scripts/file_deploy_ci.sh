#!/usr/bin/env bash
MY_NAME="[file_deploy_ci.sh]"

if [[ "$PIPELINE_DEBUG" == 1 ]]; then
  trap env EXIT
  env
  set -x
fi

if [[ "ci" != ${PIPELINE_NAMESPACE} ]]; then
  echo "*** ${MY_NAME} Invalid execution by ${PIPELINE_NAMESPACE} pipeline"
  exit
fi # "ci" == ${PIPELINE_NAMESPACE}

# Set file path for the Concert template in use
#
if [[ $# == 0 ]]; then
  # use default tempalte file path
  CONCERT_TEMPLATE_FILE_PATH=${CONCERT_TEMPLATES_PATH}/deploy-sbom-values.yaml.template
  CONCERT_TEMPLATE_FILE_TYPE="template"
elif [[ $# == 1 ]]; then
  CONCERT_TEMPLATE_FILE_PATH=$1
  CONCERT_TEMPLATE_FILE_TYPE=${1##*.}
  if [[ ${CONCERT_TEMPLATE_FILE_TYPE} != "template" ]] \
      && [[ ${CONCERT_TEMPLATE_FILE_TYPE} != "json" ]]; then
    echo "*** ${MY_NAME}: invalide extension of template file: ${CONCERT_TEMPLATE_FILE_PATH}"
    exit 1
  fi
else
  echo "*** ${MY_NAME}: Usage: $0 [<template_file_path>]"
  echo "This script generates and unloads a Concert deploy inventory file."
  echo "It uses the default value when <template_file_path> is not specified."
  echo "DevSecOps data and shell variables are used to activate a tempalte instance."
  echo "A JSON template filename should end with .json"
  echo "A YAML template filename should end with .template"
  echo "YAML tempalte instances are activated via a Concert Toolkit helper script."
  exit 1
fi

if [[ ! -f ${CONCERT_TEMPLATE_FILE_PATH} ]]; then
    echo "*** ${MY_NAME}: File not found: ${CONCERT_TEMPLATE_FILE_PATH}"
    exit 1
fi

if [[ ${CONCERT_TEMPLATE_FILE_TYPE} == "template" ]]; then
  SH_DEPLOY_INVENTORY="${CONCERT_HELPERS_PATH}/create-deploy-sbom.sh"
  if [[ ! -f  ${SH_DEPLOY_INVENTORY} ]]; then
    echo "*** ${MY_NAME} File not found: ${SH_DEPLOY_INVENTORY}"
    exit 1
  fi
fi

# Set default export variables for the template in use
#
export ENVIRONMENT_TARGET=$(get_env target-environment "qa")

export DEPLOYMENT_REPO_NAME=${ONE_PIPELINE_REPO##*/}
export DEPLOYMENT_REPO_URL=${ONE_PIPELINE_REPO}
export DEPLOYMENT_REPO_BRANCH=${ONE_PIPELINE_CONFIG_BRANCH}
export DEPLOYMENT_REPO_COMMIT_SHA=${COMMIT_SHA}

##
# Reload latest commit of inventory repo for info on the target images
#
INVENTORY_PATH=${WORKSPACE}/inventory-repo
if [[ -d ${INVENTORY_PATH} ]] && [[ -d ${INVENTORY_PATH}/.git ]]; then
  pushd ${INVENTORY_PATH}
    git pull
  popd
else
  INVENTORY_PATH=${WORKSPACE}/$(get_env INVENTORY_REPO_NAME)
  pushd ${INVENTORY_PATH}
    git pull origin $(get_env target-environment)
  popd
fi
echo "*** ${MY_NAME} INVENTORY_PATH: ${INVENTORY_PATH}"

CONCERT_VERSION=$(get_env concert-version "1.0.1")
if [[ ${CONCERT_VERSION} == "1.0.1" ]]; then
  while read -r artifact; do
    type="$(load_artifact "${artifact}" type)"
    if [[ ${type} == "concert_deploy" ]]; then

      # Set export variables specific for the deployed image
      #
      # Note: One image per deployment in Concert 1.0.1
      #
      export DEPLOYMENT_BUILD_NUMBER="$(load_artifact "${artifact}" deployment_build_number)"
      export ENV_PLATFORM="$(load_artifact "${artifact}" env_platform)"
      export K8_PLATFORM="$(load_artifact "${artifact}" k8_platform)"
      export CLUSTER_ID="$(load_artifact "${artifact}" cluster_id)"
      export CLUSTER_REGION="$(load_artifact "${artifact}" cluster_region)"
      export CLUSTER_NAME="$(load_artifact "${artifact}" cluster_name)"
      export CLUSTER_NAMESPACE="$(load_artifact "${artifact}" cluster_namespace)"
      export APP_URL="$(load_artifact "${artifact}" app_url)"

      export IMAGE_ENTRY_NAME="$(load_artifact "${artifact}" name)"

      ##
      # Find the deployed image inventory object by $IMAGE_ENTRY_ARTIFACT
      #
      while read -r inventory_entry; do
        inventory_file=${INVENTORY_PATH}/${inventory_entry}
        if [[ $(jq empty ${inventory_file} >/dev/null 2>&1; echo $?) == 0 ]]; then
          if [[ $(jq 'has("type")' ${inventory_file}) ]] \
              && [[ $(jq 'select(.type == "image")' ${inventory_file}) ]] \
              && [[ $(jq 'select(.name == $ENV.IMAGE_ENTRY_NAME)' ${inventory_file}) ]]; then
            inventory_obj=$(cat "${inventory_file}")

            export IMAGE_URI=$(echo ${inventory_obj} | jq -r '.artifact')
            export IMAGE_PURL=${IMAGE_URI%@*}
            export IMAGE_NAME=${IMAGE_PURL%:*}
            export IMAGE_TAG=${IMAGE_PURL##*:}
            export IMAGE_DIGEST=${IMAGE_URL##*@}

            export COMPONENT_NAME=$(echo ${inventory_obj} | jq -r '.name')
            export INVENTORY_BUILD=$(echo ${inventory_obj} | jq -r '.build_number')

            mkdir -p ${CONCERT_DATA_PATH}/${INVENTORY_BUILD}/${ENVIRONMENT_TARGET}
            export OUTPUTDIR=${CONCERT_DATA_PATH}/${INVENTORY_BUILD}/${ENVIRONMENT_TARGET}

            # Generate JSON-formatted Concert deploy inventory SBOM via a JSON/YAML template
            #
            export DEPLOY_FILENAME="${COMPONENT_NAME}-${INVENTORY_BUILD}-${ENVIRONMENT_TARGET}-deploy.json"

            if [[ ${CONCERT_TEMPLATE_FILE_TYPE} == "json" ]]; then
              envsubst < ${CONCERT_TEMPLATE_FILE_PATH} \
                > ${OUTPUTDIR}/${DEPLOY_FILENAME}
            else # ${CONCERT_TEMPLATE_FILE_TYPE} == "template"
              CONCERT_DEF_CONFIG_FILE="${COMPONENT_NAME}-${INVENTORY_BUILD}-${ENVIRONMENT_TARGET}-deploy-config.yaml"
              envsubst < ${CONCERT_TEMPLATE_FILE_PATH} \
                > ${OUTPUTDIR}/${CONCERT_DEF_CONFIG_FILE}
              ${SH_DEPLOY_INVENTORY} --outputdir ${OUTPUTDIR} \
                --configfile ${CONCERT_DEF_CONFIG_FILE}
            fi

            # Conditionally upload file to a COS/S3 bucket
            #
            if [[ -s ${OUTPUTDIR}/${DEPLOY_FILENAME} ]] \
                && [[ 0 != $(get_env concert-if-cos 0) ]]; then
              cocoa artifact upload \
                --backend="cos" \
                --namespace="$(get_env cos-namespace "cocoa")" \
                --pipeline-run-id="${COMPONENT_NAME}/${INVENTORY_BUILD}/${ENVIRONMENT_TARGET}" \
                --upload-path "${DEPLOY_FILENAME}" \
                ${OUTPUTDIR}/${DEPLOY_FILENAME}
            fi

            # Upload file to Concert
            #
            envsubst < ${CONCERT_TEMPLATES_PATH}/deploy_load_config.yaml.template \
              > ${OUTPUTDIR}/config.yaml

            ${CONCERT_HELPERS_PATH}/concert_upload.sh --outputdir ${OUTPUTDIR}
            break
          fi
        fi
      done < <(ls -1 ${INVENTORY_PATH})
    fi
  done < <(list_artifacts)
elif [[ ${CONCERT_VERSION} == "1.0.2" ]]; then
  echo "*** ${MY_NAME} Unsupported Concert version (WIP): ${CONCERT_VERSION}"
  exit 1
else
  echo "*** ${MY_NAME} Unsupported Concert version: ${CONCERT_VERSION}"
  exit 1
fi
