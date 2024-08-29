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
    echo "Usage: $(basename $0) --outputfile <filename for the generated json> --cdxgen-args "<cdxgen parameters>" "
    echo "Example: $(basename $0) --outputfile cyclondx.json --cdxgen-args "--project-name appname --project-version 1.0.0" "
    exit 1
}

if [ "$#" -eq 0 ]; then
    usage
fi

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --outputfile)
            outputfile="$2"
            [ -z "$outputfile" ] && { echo "Error: --outputfile <filename for the generated json> is required."; usage; }
            shift 2
            ;;
        --cdxgen-args)
            CDXGEN_ARGS="$2"
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

export OUTPUT_FILENAME=$outputfile 

CODE_SCAN_COMMAND="code-scan --src /concert-sample --output-file ${OUTPUT_FILENAME} --cdxgen-args \"${CDXGEN_ARGS}\" "
echo "${CONTAINER_COMMAND} ${OPTIONS} -v ${SRC_PATH}:/concert-sample -v ${OUTPUTDIR}:/toolkit-data ${CONCERT_TOOLKIT_IMAGE} bash -c ${CODE_SCAN_COMMAND}"
${CONTAINER_COMMAND} ${OPTIONS} -v ${SRC_PATH}:/concert-sample -v ${OUTPUTDIR}:/toolkit-data ${CONCERT_TOOLKIT_IMAGE} bash -c "${CODE_SCAN_COMMAND}"
