#!/bin/bash
##########################################################################
# Copyright IBM Corp. 2024.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
# the License. You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
# an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
# specific language governing permissions and limitations under the License.
##########################################################################


scriptdir=`dirname $0`
cd ${scriptdir}
scriptdir=`pwd`
sourcecodedir=$(builtin cd $scriptdir/..; pwd)

VARIABLES_FILE=${sourcecodedir}/concert_data/demo_build_envs.variables

source ${VARIABLES_FILE}


export OUTPUTDIR=${sourcecodedir}/concert_data
export SRC_PATH=${sourcecodedir}/src

mkdir ${OUTPUTDIR}/${COMPONENT_BUILD_NUMBER}
export OUTPUTDIR=${OUTPUTDIR}/${COMPONENT_BUILD_NUMBER}

echo "All files generated from this script will be saved in: ${OUTPUTDIR}"

cdxgen_vars="--project-name ${COMPONENT_SOURCECODE_REPO_URL} --project-version ${COMPONENT_VERSION}"
echo -e "\n#####"
echo "# Source code scanning stage #"
echo "# ./concert-utils/helpers/create-code-cyclonedx-sbom.sh --outputfile ${COMPONENT_SOURCECODE_REPO_NAME}-cyclonedx-sbom-${COMPONENT_BUILD_NUMBER}.json --cdxgen-args ${cdxgen_vars}"
echo "#####"
./concert-utils/helpers/create-code-cyclonedx-sbom.sh --outputfile "${COMPONENT_SOURCECODE_REPO_NAME}-cyclonedx-sbom-${COMPONENT_BUILD_NUMBER}.json" --cdxgen-args "${cdxgen_vars}"

echo -e "\n#####"
echo "# Build image stage #"
echo "#####"

./build.sh
source ${VARIABLES_FILE}

export CYCLONEDX_FILENAME=${COMPONENT_SOURCECODE_REPO_NAME}-cyclonedx-sbom-${COMPONENT_BUILD_NUMBER}.json

# echo "#####"
# echo "# image scanning stage "
# echo "# ./concert-utils/helpers/create-image-cyclonedx-sbom.sh --outputfile ${CYCLONEDX_FILENAME}"
# echo "#####"
#./concert-utils/helpers/create-image-cyclonedx-sbom.sh --outputfile ${CYCLONEDX_FILENAME}

echo -e "\n#####"
echo "# Generate Concert Build SBOM"

export BUILD_FILENAME=${COMPONENT_NAME}-build-inventory-${COMPONENT_BUILD_NUMBER}.json

CONCERT_DEF_CONFIG_FILE=build-${COMPONENT_NAME}-${COMPONENT_BUILD_NUMBER}-config.yaml

echo "envsubst < ${scriptdir}/${TEMPLATE_PATH}/build-sbom-values.yaml.template > ${OUTPUTDIR}/${CONCERT_DEF_CONFIG_FILE}"
envsubst < ${scriptdir}/${TEMPLATE_PATH}/build-sbom-values.yaml.template > ${OUTPUTDIR}/${CONCERT_DEF_CONFIG_FILE}

echo "# ./concert-utils/helpers/create-build-sbom.sh --outputdir ${OUTPUTDIR} --configfile ${CONCERT_DEF_CONFIG_FILE}"
echo "#####"
./concert-utils/helpers/create-build-sbom.sh --outputdir ${OUTPUTDIR} --configfile ${CONCERT_DEF_CONFIG_FILE}

echo -e "\n#####"
echo "# Send to Concert stage"
echo "#./concert-utils/helpers/concert_upload_data.sh"
echo "#####"
envsubst < ${scriptdir}/${TEMPLATE_PATH}/simulating_ci_config.yaml.template > ${OUTPUTDIR}/config.yaml
./concert-utils/helpers/concert_upload.sh --outputdir ${OUTPUTDIR}

echo "export INVENTORY_BUILD=${COMPONENT_BUILD_NUMBER}" >> ${VARIABLES_FILE}
newbuild=$(( $COMPONENT_BUILD_NUMBER + 1 ))
echo export COMPONENT_BUILD_NUMBER=${newbuild}  >> ${VARIABLES_FILE}
