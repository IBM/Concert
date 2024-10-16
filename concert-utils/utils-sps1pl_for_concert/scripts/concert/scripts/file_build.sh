#!/usr/bin/env bash
MY_NAME="[file_build.sh]"

if [[ "$PIPELINE_DEBUG" == 1 ]]; then
  trap env EXIT
  env
  set -x
fi

if [[ "ci" != ${PIPELINE_NAMESPACE} ]]; then
  exit
fi
# "ci" == ${PIPELINE_NAMESPACE}

# Set alias for the output directory of Concert Toolkit image
#
# Note: Several export variables have been set in DevSecOps scripts/finish_concert.sh
#
export ENVIRONMENT_TARGET=$(get_env target-environment "qa")
if [[ -z ${OUTPUTDIR} ]]; then
  mkdir -p ${CONCERT_DATA_PATH}/${INVENTORY_BUILD}/${ENVIRONMENT_TARGET}
  export OUTPUTDIR=${CONCERT_DATA_PATH}/${INVENTORY_BUILD}/${ENVIRONMENT_TARGET}
fi

# Set file path for the Concert template in use
#
if [[ $# == 0 ]]; then
  # use default tempalte file path
  CONCERT_TEMPLATE_FILE_PATH=${CONCERT_TEMPLATES_PATH}/build-sbom-values.yaml.template
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
  echo "This script generates and unloads a Concert build inventory file."
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
  SH_BUILD_INVENTORY="${CONCERT_HELPERS_PATH}/create-build-sbom.sh"
  if [[ ! -f  ${SH_BUILD_INVENTORY} ]]; then
    echo "*** ${MY_NAME} File not found: ${SH_BUILD_INVENTORY}"
    exit 1
  fi
fi

###
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

  # Get all JSON-formatted inventory entries of type "image"
  #
  while read -r filename; do
    inventory_file=${INVENTORY_PATH}/${filename}

    if [[ $(jq empty ${inventory_file} >/dev/null 2>&1; echo $?) == 0 ]]; then
      if [[ $(jq 'has("type")' ${inventory_file}) ]] \
          && [[ $(jq 'select(.type == "image")' ${inventory_file}) ]]; then
        ##
        # Set additional export variables for the Concert build template
        #
        # Note: Every Concert "build" inventory includes at most one image in v1.0.1
        ##

        # Note: $inventory_obj is needed to prevent wrong build file overwritten
        # when one inventory contains several image files.
        #
        inventory_obj=$(cat "${inventory_file}")

        CONCERT_VERSION=$(get_env concert-version "1.0.1")
        if [[ ${CONCERT_VERSION} == "1.0.1" ]]; then

          # Set export variables for YAML-formatted build template of Concert 1.0.1
          #
          export COMPONENT_NAME=$(echo ${inventory_obj}| jq -r ".name")
          export BUILD_NUMBER=$(echo ${inventory_obj}| jq -r ".build_number")

          export REPO_URL=$(echo ${inventory_obj}| jq -r ".repository_url")
          export REPO_NAME=${REPO_URL##*/}
          export REPO_BRANCH=$(get_env one-pipeline-config-branch "main")
          export REPO_COMMIT_SHA=$(echo ${inventory_obj}| jq -r ".commit_sha")

          export IMAGE_URL=$(echo ${inventory_obj}| jq -r ".artifact")
          export IMAGE_PURL=${IMAGE_URL%@*}
          export IMAGE_NAME=${IMAGE_PURL%:*}
          export IMAGE_TAG=${IMAGE_PURL##*:}
          export IMAGE_DIGEST=${IMAGE_URL##*@}
        elif [[ ${CONCERT_VERSION} == "1.0.2" ]]; then
          echo "*** ${MY_NAME} Unsupported Concert version (WIP): ${CONCERT_VERSION}"
          exit 1
        else
          echo "*** ${MY_NAME} Unsupported Concert version: ${CONCERT_VERSION}"
          exit 1
        fi

        # Generate JSON-formatted Concert build inventory SBOM via a JSON/YAML template
        #
        # Note: ${COMPONENT_NAME} is name of the "image" inventory in use,
        #   not the default value ${APP_REPO_NAME}
        #
        export BUILD_FILENAME="${APP_REPO_NAME}-${COMPONENT_NAME}-${BUILD_NUMBER}-build.json"

        if [[ ${CONCERT_TEMPLATE_FILE_TYPE} == "json" ]]; then
          envsubst < ${CONCERT_TEMPLATE_FILE_PATH} \
            > ${OUTPUTDIR}/${BUILD_FILENAME}
        else # ${CONCERT_TEMPLATE_FILE_TYPE} == "template"
          CONCERT_DEF_CONFIG_FILE="${COMPONENT_NAME}-${BUILD_NUMBER}-build-config.yaml"
          envsubst < ${CONCERT_TEMPLATE_FILE_PATH} \
            > ${OUTPUTDIR}/${CONCERT_DEF_CONFIG_FILE}
          ${SH_BUILD_INVENTORY} --outputdir ${OUTPUTDIR} \
            --configfile ${CONCERT_DEF_CONFIG_FILE}
        fi

        # Conditionally upload file to a COS/S3 bucket
        #
        if [[ -s ${OUTPUTDIR}/${BUILD_FILENAME} ]] \
            && [[ 0 != $(get_env concert-if-cos 0) ]]; then
          cocoa artifact upload \
            --backend="cos" \
            --namespace="$(get_env cos-namespace "cocoa")" \
            --pipeline-run-id="${APP_REPO_NAME}/${BUILD_NUMBER}/${ENVIRONMENT_TARGET}" \
            --upload-path "${BUILD_FILENAME}" \
            ${OUTPUTDIR}/${BUILD_FILENAME}
        fi

        # Upload file to Concert
        #
        envsubst < ${CONCERT_TEMPLATES_PATH}/build_load_config.yaml.template \
          > ${OUTPUTDIR}/config.yaml

        ${CONCERT_HELPERS_PATH}/concert_upload.sh --outputdir ${OUTPUTDIR}
      fi
    fi
  done < <(ls -1 ${INVENTORY_PATH})
elif [[ ${CONCERT_VERSION} == "1.0.2" ]]; then
  echo "*** ${MY_NAME} Unsupported Concert version (WIP): ${CONCERT_VERSION}"
  exit 1
else
  echo "*** ${MY_NAME} Unsupported Concert version: ${CONCERT_VERSION}"
  exit 1
fi