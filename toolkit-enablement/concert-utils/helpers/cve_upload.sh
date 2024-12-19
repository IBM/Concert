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

UPLOAD_CVE_COMMAND="upload-concert --upload-config /toolkit-data/cve-config.yaml"
echo "${CONTAINER_COMMAND} ${OPTIONS} -v ${outputdir}:/toolkit-data ${CONCERT_TOOLKIT_IMAGE} bash -c ${UPLOAD_CVE_COMMAND}"
${CONTAINER_COMMAND} ${OPTIONS} -v ${outputdir}:/toolkit-data ${CONCERT_TOOLKIT_IMAGE} bash -c "${UPLOAD_CVE_COMMAND}"