#!/usr/bin/env bash
MY_NAME="[file_application-def.sh]"

if [[ "$PIPELINE_DEBUG" == 1 ]]; then
  trap env EXIT
  env
  set -x
fi

if [[ "ci" != ${PIPELINE_NAMESPACE} ]]; then
  exit
fi

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
  CONCERT_TEMPLATE_FILE_PATH=${CONCERT_TEMPLATES_PATH}/app-sbom-values.yaml.template
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
  SH_APP_DEFINITION="${CONCERT_HELPERS_PATH}/create-application-sbom.sh"
  if [[ ! -f  ${SH_APP_DEFINITION} ]]; then
    echo "*** ${MY_NAME} File not found: ${SH_APP_DEFINITION}"
    exit 1
  fi
fi

CONCERT_VERSION=$(get_env concert-version "1.0.1")
if [[ ${CONCERT_VERSION} == "1.0.1" ]]; then

  export REPO_NAME=${APP_REPO_NAME}
  export REPO_URL=${APP_REPO}

##
# Reload latest commit of inventory repo for info on the target image
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

  ##
  # Get image registry name (IMAGE_NAME)
  #
  while read -r filename; do
    inventory_file=${INVENTORY_PATH}/${filename}
    if [[ $(jq empty ${inventory_file} >/dev/null 2>&1; echo $?) == 0 ]]; then
      if [[ $(jq 'has("type")' ${inventory_file}) ]] \
          && [[ $(jq 'select(.type == "image")' ${inventory_file}) ]] \
          && [[ $(jq 'select(.repository_url == $ENV.REPO_URL)' ${inventory_file}) ]]; then

        inventory_obj=$(cat "${inventory_file}")
        export COMPONENT_NAME=$(echo ${inventory_obj} | jq -r '.name')
        export INVENTORY_BUILD=$(echo ${inventory_obj} | jq -r '.build_number')

        export IMAGE_URI=$(echo ${inventory_obj} | jq -r ".artifact")
        export IMAGE_PURL=${IMAGE_URI%@*}
        export IMAGE_NAME=${IMAGE_PURL%:*}

        # Generate JSON-formatted Concert build inventory SBOM via a JSON/YAML template
        #
        export APP_FILE_NAME="${COMPONENT_NAME}-${INVENTORY_BUILD}-app.json"

        if [[ ${CONCERT_TEMPLATE_FILE_TYPE} == "json" ]]; then
          envsubst < ${CONCERT_TEMPLATE_FILE_PATH} \
            > ${OUTPUTDIR}/${APP_FILE_NAME}
        else # ${CONCERT_TEMPLATE_FILE_TYPE} == "template"
          CONCERT_DEF_CONFIG_FILE="${COMPONENT_NAME}-${INVENTORY_BUILD}-app-config.yaml"
          envsubst < ${CONCERT_TEMPLATE_FILE_PATH} \
            > ${OUTPUTDIR}/${CONCERT_DEF_CONFIG_FILE}
          ${SH_APP_DEFINITION} --outputdir ${OUTPUTDIR} \
            --configfile ${CONCERT_DEF_CONFIG_FILE}
        fi

        # Conditionally upload file to a COS/S3 bucket
        #
        if [[ 0 != $(get_env concert-if-cos 0) ]]; then
          cocoa artifact upload \
            --backend="cos" \
            --namespace="$(get_env cos-namespace "cocoa")" \
            --pipeline-run-id="${COMPONENT_NAME}/${INVENTORY_BUILD}/${ENVIRONMENT_TARGET}" \
            --upload-path "${APP_FILE_NAME}" \
            ${OUTPUTDIR}/${APP_FILE_NAME}
        fi

        # Upload file to Concert
        #
        envsubst < ${CONCERT_TEMPLATES_PATH}/application-def_load_config.yaml.template \
          > ${OUTPUTDIR}/config.yaml

        ${CONCERT_HELPERS_PATH}/concert_upload.sh --outputdir ${OUTPUTDIR}
        break
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
