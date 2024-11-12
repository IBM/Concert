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

CONCERT_UTILS_DIRNAME="concert-utils"

scriptdir=`dirname $0`

scriptdir=`pwd`
sourcecodedir=$(builtin cd $scriptdir/..; pwd)

VARIABLES_FILE=${sourcecodedir}/concert_data/demo_build_envs.variables
source ${VARIABLES_FILE}

# remove the existing repo directory, in case it is not named concert-utils
TOOLKIT_CLONE_FOLDER=`echo "${CONCERT_TOOLKIT_UTILS_REPO}" | awk -F"/" '{print $NF}' | awk -F"." '{print $1}'`
rm -rf "${TOOLKIT_CLONE_FOLDER}" || true

# remove the existing concert-utils directory as it will be updated
find . -type d -maxdepth 2 -name ${CONCERT_UTILS_DIRNAME} | xargs rm -rf

git clone ${CONCERT_TOOLKIT_UTILS_REPO}

# find and move the concert-utils directory in the repo to the root
concert_utils_dir=$(find . -type d -name ${CONCERT_UTILS_DIRNAME})
mv ${concert_utils_dir} . || true

# if the repo is not named concert-utils, delete it
[[ "${TOOLKIT_CLONE_FOLDER}" != "${CONCERT_UTILS_DIRNAME}" ]] && rm -rf "${TOOLKIT_CLONE_FOLDER}" || true

container_cmd=$(echo ${CONTAINER_COMMAND} | awk '{print $1}')

${container_cmd} pull ${CONCERT_TOOLKIT_IMAGE}
