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

VARIABLES_FILE=${sourcecodedir}/concert_data/demo_build_envs_z.variables

source ${VARIABLES_FILE}

export OUTPUTDIR=${sourcecodedir}/concert_data

echo "All files generated from this script will be saved in: ${OUTPUTDIR}"

###
# application toolkit config yaml
###
export APP_FILE_NAME="${APP_NAME}-${APP_VERSION}-application.json"

CONCERT_DEF_CONFIG_FILE=app-${APP_NAME}-${APP_VERSION}-config.yaml
envsubst < ${scriptdir}/${TEMPLATE_PATH}/app-sbom-values_z.yaml.template > ${OUTPUTDIR}/${CONCERT_DEF_CONFIG_FILE}

echo -e "\n#####"
echo "# Generate Concert Application SBOM"
echo "# ./concert-utils/helpers/create-application-sbom.sh --outputdir ${OUTPUTDIR} --configfile ${CONCERT_DEF_CONFIG_FILE}"
echo "####"
./concert-utils/helpers/create-application-sbom.sh --outputdir ${OUTPUTDIR} --configfile ${CONCERT_DEF_CONFIG_FILE}

echo -e "\n#####"
echo "# Send to Concert stage"
echo "#####"

envsubst < ${scriptdir}/${TEMPLATE_PATH}/application_def_load_config.yaml.template > ${OUTPUTDIR}/config.yaml
./concert-utils/helpers/concert_upload.sh --outputdir ${OUTPUTDIR}
