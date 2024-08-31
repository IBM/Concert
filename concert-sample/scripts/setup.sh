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

scriptdir=`pwd`
sourcecodedir=$(builtin cd $scriptdir/..; pwd)

VARIABLES_FILE=${sourcecodedir}/concert_data/demo_build_envs.variables
source ${VARIABLES_FILE}

TOOLKIT_CLONE_FOLDER=`echo "${CONCERT_TOOLKIT_UTILS_REPO}" | awk -F"/" '{print $NF}' | awk -F"." '{print $1}'`
rm -rf "${TOOLKIT_CLONE_FOLDER}" || true

git clone ${CONCERT_TOOLKIT_UTILS_REPO}

if which docker >/dev/null; then
    dockerexe=docker 
elif which podman >/dev/null; then
    dockerexe=podman
else
    echo "Docker or Podman is not installed. You need a container runtime environment."
    exit -1
fi

${dockerexe} pull ${CONCERT_TOOLKIT_IMAGE}
