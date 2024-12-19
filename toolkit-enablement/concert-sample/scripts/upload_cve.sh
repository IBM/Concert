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

export CVE_FILE=${sourcecodedir}/templates/vulnerability_sample.json.template
export CVE_FILE_NAME=$(basename "${CVE_FILE%.*}")
envsubst < ${CVE_FILE} > ${OUTPUTDIR}/${CVE_FILE_NAME}

echo "All files generated from this script will be saved in: ${OUTPUTDIR}"

echo -e "\n#####"
echo "# Upload CVE to Concert stage"
echo "#####"

envsubst < ${scriptdir}/${TEMPLATE_PATH}/upload-cve.yaml.template > ${OUTPUTDIR}/cve-config.yaml
./concert-utils/helpers/cve_upload.sh --outputdir ${OUTPUTDIR}