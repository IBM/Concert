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
SRC_PATH=${sourcecodedir}/src

if test -z "$IMAGE_NAME"; then
   IMAGE_NAME="concert-sample"
fi

if test -z "$IMAGE_TAG"; then
   IMAGE_TAG="sample"
fi

container_cmd=$(echo ${CONTAINER_COMMAND} | awk '{print $1}')

# shellcheck disable=SC2086
${container_cmd} build -f $SRC_PATH/Dockerfile -t ${IMAGE_NAME}:${IMAGE_TAG} $SRC_PATH

IMAGE_DIGEST="$(${container_cmd} inspect --format='{{index .RepoDigests 0}}' "${IMAGE_NAME}:${IMAGE_TAG}" 2>/dev/null | awk -F@ '{print $2}')"
if [[ -z "${IMAGE_DIGEST}" ]]; then
   echo "repo digests not available, using image id as digest"
   IMAGE_DIGEST="$(${container_cmd} inspect --format='{{index .Id}}' "${IMAGE_NAME}:${IMAGE_TAG}")"
fi

REPO_COMMIT_SHA="$(git rev-parse HEAD)"
REPO_BRANCH="$(git rev-parse --abbrev-ref HEAD)"

echo -e "export COMPONENT_IMAGE_DIGEST=${IMAGE_DIGEST}" >> ${VARIABLES_FILE}
echo -e "export COMPONENT_SOURCECODE_REPO_BRANCH=${REPO_BRANCH}"  >> ${VARIABLES_FILE}
echo -e "export COMPONENT_SOURCECODE_REPO_COMMIT_SHA=${REPO_COMMIT_SHA}"  >> ${VARIABLES_FILE}
echo -e "export DEPLOYMENT_REPO_COMMIT_SHA=${REPO_COMMIT_SHA}"  >> ${VARIABLES_FILE}
