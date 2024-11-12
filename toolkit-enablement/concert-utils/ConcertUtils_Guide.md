# Concert-Toolkit Utils Guide

## Table of Contents

1. [Concert-Utils Overview](#Concert-Utils-Overview)
2. [Installation](#Installation)
3. [Utilities in Concert-Utils](#Utilities-in-Concert-Utils)
    1. [Create Concert Application SBoM](#Create-Concert-Application-SBoM)
    2. [Create Concert Build SBoM](#Create-Concert-Build-SBoM)
    3. [Create Concert Deploy SBoM](#Create-Concert-Deploy-SBoM)
    4. [Create CycloneDX package SBoM](#Create-CycloneDX-package-SBoM)
    5. [Upload data to Concert](#Upload-data-to-Concert)

## Concert-Utils Overview

Concert-Utils is a set of utilities to simplify the usage of the IBM Concert Toolkit container image and integrate it to any automation engine that can run container images.  

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
specific language governing permissions and limitations under the License.It is provided AS IS, and as an educational mechanism for interacting with the ibm-concert-toolkit image.

## Installation

You can clone or fork the concert-util github project. The utilities provided here can be used from any automation infrastructure. 

## Utilities in Concert-Utils

To use the helper command, you need to create the following environment variables:

export CONTAINER_COMMAND="docker run"
export OPTIONS="-it --rm -u $(id -u):$(id -g)"

CONTAINER_COMMAND can be replace for from "docker run" to "podman run" depending on your environment.
OPTIONS includes the runtime arguments to pass to CONTAINER_COMMAND depending on your environment and command to control user, running an executable, or other aspects to execute the command.

### Create Concert Application SBoM

This utility generates a JSON-formatted application file per the ConcertDef Schema using the `app-sbom` tool provided in the IBM Concert Toolkit.

Usage:
```
./concert-utils/helpers/create-application-sbom.sh --outputdir <output_directory> --configfile <build-config.yaml>
```

### Create Concert Build SBoM

This utility generates a JSON-formatted Build inventory file per the ConcertDef Schema, using the `build-sbom` tool provided in the IBM Concert Toolkit.

Usage:
```
./concert-utils/helpers/create-build-sbom.sh --outputdir <output_directory> --configfile <build-config.yaml>
```

### Create Concert Deploy SBoM

This utility generates a JSON-formatted deploy inventory file per the ConcertDef Schema, using the `deploy-sbom` tool provided in the IBM Concert Toolkit.

Usage:
```
./concert-utils/helpers/create-deploy-sbom.sh --outputdir <output_directory> --configfile <build-config.yaml>
```

### Create CycloneDX package SBoM

This utility generates a JSON-formatted CycloneDX package SBoM using `code-scan` tool provided in the IBM Concert Toolkit.

Usage:
```
./concert-utils/helpers/create-image-cyclonedx-sbom.sh --outputfile "cyclonedx-filename.json"
```

### Upload data to Concert

This utility uploads one or more Concert-supported files to Concert. The utility uses the `upload-concert` tool provided in the IBM Concert Toolkit.

Usage:
```
./concert-utils/helpers/concert_upload.sh --outputdir 
```
