#!/usr/bin/env bash
MY_NAME="[file_cyclonedx.sh]"

if [[ "$PIPELINE_DEBUG" == 1 ]]; then
  trap env EXIT
  env
  set -x
fi

if [[ "ci" != ${PIPELINE_NAMESPACE} ]]; then
  exit
fi
# "ci" == ${PIPELINE_NAMESPACE}

export COMPONENT_NAME=$(get_env APP_REPO_NAME)
export CYCLONEDX_FILENAME="${COMPONENT_NAME}-${BUILD_NUMBER}-cyclonedx-code.json"

# Set alias for the output directory of Concert Toolkit image
#
export ENVIRONMENT_TARGET=$(get_env target-environment "qa")
if [[ -z ${OUTPUTDIR} ]]; then
  mkdir -p ${CONCERT_DATA_PATH}/${BUILD_NUMBER}/${ENVIRONMENT_TARGET}
  export OUTPUTDIR=${CONCERT_DATA_PATH}/${BUILD_NUMBER}/${ENVIRONMENT_TARGET}
fi

# Get CRA-generated Package SBOMs for all code repos
#
CONCERT_VERSION=$(get_env concert-version "1.0.1")
while read -r repo; do
  CRA_SBOM_FILENAME=cra_sbom_cyclonedx_${repo}
  load_file "${CRA_SBOM_FILENAME}" > ${CRA_SBOM_FILENAME}
  if [[ -s ${CRA_SBOM_FILENAME} ]]; then

    # Customize CRA-generated code-repo based Package SBOM 

    if [[ ${CONCERT_VERSION} == "1.0.1" ]]; then
      #   - set .matadata.component.name as repo URL for Concert 1.0.1
      #
      export TMP_REPO_URL=$(load_repo ${repo} url)
      jq  '.metadata.component.name = $ENV.TMP_REPO_URL' ${CRA_SBOM_FILENAME} \
        >  ${OUTPUTDIR}/${CYCLONEDX_FILENAME}
    else
      mv ${CRA_SBOM_FILENAME} ${OUTPUTDIR}/${CYCLONEDX_FILENAME}
    fi

    # Conditionally upload file to COS
    #
    if [[ 0 != $(get_env concert-if-cos 0) ]]; then
      cocoa artifact upload \
        --backend="cos" \
        --namespace="$(get_env cos-namespace "cocoa")" \
        --pipeline-run-id="${COMPONENT_NAME}/${BUILD_NUMBER}/${ENVIRONMENT_TARGET}" \
        --upload-path "${CYCLONEDX_FILENAME}" \
        ${OUTPUTDIR}/${CYCLONEDX_FILENAME}
    fi

    # Upload file to Concert
    #
    envsubst < ${CONCERT_TEMPLATES_PATH}/cyclonedx_load_config.yaml.template \
      > ${OUTPUTDIR}/config.yaml

    ${CONCERT_HELPERS_PATH}/concert_upload.sh --outputdir ${OUTPUTDIR}
  else
    echo "### ${MY_NAME} CRA-generated package SBOM is not available for repo ${repo}"
  fi
done < <(list_repos)
