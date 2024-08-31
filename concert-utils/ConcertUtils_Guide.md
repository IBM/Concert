# Concert-Toolkit Utils Guide

[TOC]

## Concert-Utils Overview

Concert-Utils is a set of utilities to simplify the usage of the cocnert toolkit docker image and integrate it to any automation engine that can run container images.  

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
specific language governing permissions and limitations under the License.It is provided AS IS, and as an educational mechanism for interacting with the ibm-concert image    

## Installation

You can clone or fork the concert-util github project.    The utilities provided here can be used from any automation infrastrcutre. 

## Utilities in Concert-Utils

To use the helper command you need to create teh following environment variables

export CONTAINER_COMMAND="docker run"
export OPTIONS="-it --rm -u $(id -u):$(id -g)"

CONTAINER_COMMAND can be replace for from "docker run" to "podman run" depending on your environment.  Option
OPTIONS inclues the differnet option depending on your environment and command to control user, running an executable, or other aspects to execute the command.

### Create concert application sbom

This utility generates a JSON-formatted application file per the ConcertDef Schema using the app-sbom command provided in the IBM Concert Toolkit.

Usage:
```
./concert-utils/helpers/create-application-sbom.sh --outputdir <output_directory> --configfile <build-config.yaml>
```

### Create concert build sbom

This utility generates a JSON-formatted Build inventory file per the ConcertDef Schema using the app-sbom command provided in the IBM Concert Toolkit.

Usage:
```
./concert-utils/helpers/create-build-sbom.sh --outputdir <output_directory> --configfile <build-config.yaml>
```

### Create cocnert deploy sbom

This utility generates a JSON-formatted deploy inventory file per the ConcertDef Schema, using deploy-sbom tool from the concert toolkit.

Usage:
```
./concert-utils/helpers/create-deploy-sbom.sh --outputdir <output_directory> --configfile <build-config.yaml>
```

### Create cyclongdx sbom

This utility generates a JSON-formatted Cyclonedx using code-scan tool from the concert toolkit

Usage:
```
./concert-utils/helpers/create-image-cyclondx-sbom.sh --outputfile "cyclonedx-filename.json"
```

### Uploade data to concert

This utility uploads one or more Concert-supported files to Concert. The utility uses upload-conert command
provided in the IBM Concert Toolkit.

Usage:
```
./concert-utils/helpers/concert_upload.sh --outputdir 
```