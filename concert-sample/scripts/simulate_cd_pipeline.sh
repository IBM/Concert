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

export OUTPUTDIR=${sourcecodedir}/concert_data/${INVENTORY_BUILD}
echo "all files generated from this script will be save here ${OUTPUTDIR}"
echo ""

echo "#####"
echo "# gen concert deploy inventory #"
echo "####"
export DEPLOY_FILENAME="${COMPONENT_NAME}-deploy-inventory-${BUILD_NUMBER}.json"

CONCERT_DEF_CONFIG_FILE=deploy-${COMPONENT_NAME}-${BUILD_NUMBER}-config.yaml
envsubst < ${scriptdir}/${TEMPLATE_PATH}/deploy-sbom-values.yaml.template > ${OUTPUTDIR}/${CONCERT_DEF_CONFIG_FILE}

echo "generating deploy sbom"
echo "./concert-utils/helpers/create-deploy-sbom.sh --outputdir ${OUTPUTDIR} --configfile ${CONCERT_DEF_CONFIG_FILE}" 
./concert-utils/helpers/create-deploy-sbom.sh --outputdir ${OUTPUTDIR} --configfile ${CONCERT_DEF_CONFIG_FILE}

###
# upload build file
###
#echo "generating config file inventory json ${OUTPUTDIR}/${outfile_name} "
envsubst < ${scriptdir}/${TEMPLATE_PATH}/simulating_cd_config.yaml.template > ${OUTPUTDIR}/config.yaml
./concert-utils/helpers/concert_upload.sh --outputdir ${OUTPUTDIR}
