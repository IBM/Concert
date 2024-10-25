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


usage() {
    echo "Usage: $(basename $0) --outputdir <outputdirectory for generated files> --configfile <application-config-file>"
    echo "Example: $(basename $0) --outputdir <outputdirectory for generated files> --configfile application-config.yaml"
    exit 1
}

if [ "$#" -eq 0 ]; then
    usage
fi

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --configfile)
            configfile="$2"
            [ -z "$configfile" ] && { echo "Error:  --configfile <application-config-file> is required."; usage; }
            shift 2
            ;;
        --outputdir)
            outputdir="$2"
            [ -z "$outputdir" ] && { echo "Error: --outputdir <outputdirectory for generated files>  is required."; usage; }
            shift 2
            ;;
        --help)
            usage
            ;;
        *)
            echo "Unknown parameter passed: $1"
            usage
            ;;
    esac
done

if which docker >/dev/null; then
    dockerexe=docker
elif which podman >/dev/null; then
    dockerexe=podman
else
    echo "docker or podman are not installed need a container runtime environment"
    exit -1
fi

TOOLKIT_COMMAND="deploy-sbom --deploy-config /toolkit-data/${configfile}"
echo "${CONTAINER_COMMAND} ${OPTIONS} -v ${outputdir}:/toolkit-data ${CONCERT_TOOLKIT_IMAGE} bash -c ${TOOLKIT_COMMAND}"
${CONTAINER_COMMAND} ${OPTIONS} -v ${outputdir}:/toolkit-data ${CONCERT_TOOLKIT_IMAGE} bash -c "${TOOLKIT_COMMAND}"

