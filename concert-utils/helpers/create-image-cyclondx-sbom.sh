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

if which docker >/dev/null; then
    dockerexe=docker 
elif which podman >/dev/null; then
    dockerexe=podman
else
    echo "docker or podman are not installed need a container runtime environment"
    exit -1
fi

SCAN_COMMAND="image-scan --images ${IMAGE_NAME}:${IMAGE_TAG}"
echo "${CONTAINER_COMMAND} ${OPTIONS} -v ${SRC_PATH}:/concert-sample-src -v ${OUTPUTDIR}:/toolkit-data ${CONCERT_TOOLKIT_IMAGE} bash -c ${SCAN_COMMAND}"
${CONTAINER_COMMAND} ${OPTIONS} -v ${SRC_PATH}:/concert-sample-src -v ${OUTPUTDIR}:/toolkit-data ${CONCERT_TOOLKIT_IMAGE} bash -c "${SCAN_COMMAND}"