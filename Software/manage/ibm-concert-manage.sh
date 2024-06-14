#!/bin/bash
set -e

scriptdir=`dirname $0`
cd ${scriptdir}
scriptdir=`pwd`
dockerexe=${DOCKER_EXE:-podman}
docker_image=${UTILS_IMG:-"cp.icr.io/cpopen/concert/aaf-utils:latest"}
work_dir=${WORK_DIR:-"${scriptdir}/.ibm-concert-manage-utils"}

container_name=ibm-aaf-utils
tools_container_name=ibm-concert-toolbox
release="4.8.3" # AAF Release
components=${COMPONENTS:-"cpd_platform,concert"} 
service_name=concert
service_version=${SERVICE_VERSION:-"1.0.0"} # Concert Release
preview=${PREVIEW:-"false"}
action=${ACTION:-"install"}


# Write environment variables to <work_dir>/ibm-concert-manage.env
function create_env_file {
  # Remove ibm-concert-manage.env file if it exists
  if test -f ${work_dir}/ibm-concert-manage.env; then
      rm -f ${work_dir}/ibm-concert-manage.env
  fi
  echo "export DOCKER_EXE=${DOCKER_EXE:-podman}" >> ${work_dir}/ibm-concert-manage.env
  echo "export UTILS_IMG=${UTILS_IMG:-"cp.icr.io/cpopen/concert/aaf-utils:latest"}" >> ${work_dir}/ibm-concert-manage.env
  echo "export WORK_DIR=${WORK_DIR:-"${scriptdir}/.ibm-concert-manage-utils"}" >> ${work_dir}/ibm-concert-manage.env
  echo "export container_name=ibm-aaf-utils" >> ${work_dir}/ibm-concert-manage.env
  echo "export COMPONENTS=${COMPONENTS:-"cpd_platform,concert"}" >> ${work_dir}/ibm-concert-manage.env 
  echo "export PREVIEW=${PREVIEW:-"false"}" >> ${work_dir}/ibm-concert-manage.env 
  echo "export ACTION=${ACTION:-"install"}" >> ${work_dir}/ibm-concert-manage.env 
  echo "export SERVICE_VERSION=${SERVICE_VERSION:-"1.0.0"}" >> ${work_dir}/ibm-concert-manage.env 
  echo "export OCP_URL=<enter your Red Hat OpenShift Container Platform URL>" >> ${work_dir}/ibm-concert-manage.env
  echo "export OPENSHIFT_TYPE=<enter your deployment type>" >> ${work_dir}/ibm-concert-manage.env
  echo "export IMAGE_ARCH=<enter your cluster architecture>" >> ${work_dir}/ibm-concert-manage.env
  echo "export PROJECT_OPERATOR=<enter your IBM Automation operator installation project>" >> ${work_dir}/ibm-concert-manage.env
  echo "export PROJECT_INSTANCE=<enter your IBM Concert installation project>" >> ${work_dir}/ibm-concert-manage.env
  echo "# export PROJECT_TETHERED=<enter the tethered project>" >> ${work_dir}/ibm-concert-manage.env
  echo "export STG_CLASS_BLOCK=<RWO-storage-class-name>" >> ${work_dir}/ibm-concert-manage.env
  echo "export STG_CLASS_FILE=<RWX-storage-class-name>" >> ${work_dir}/ibm-concert-manage.env
  echo "# export IBM_ENTITLEMENT_KEY=<enter your IBM entitlement API key>" >> ${work_dir}/ibm-concert-manage.env
  echo "# export PRIVATE_REGISTRY_LOCATION=<enter the location of your private container registry>" >> ${work_dir}/ibm-concert-manage.env
  echo "# export PRIVATE_REGISTRY_PUSH_USER=<enter the username of a user that can push to the registry>" >> ${work_dir}/ibm-concert-manage.env
  echo "# export PRIVATE_REGISTRY_PUSH_PASSWORD=<enter the password of the user that can push to the registry>" >> ${work_dir}/ibm-concert-manage.env
  echo "# export PRIVATE_REGISTRY_PULL_USER=<enter the username of a user that can pull from the registry>" >> ${work_dir}/ibm-concert-manage.env
  echo "# export PRIVATE_REGISTRY_PULL_PASSWORD=<enter the password of the user that can pull from the registry>" >> ${work_dir}/ibm-concert-manage.env
  # for airgap install
  echo "# export PRIVATE_IMAGE_REGISTRY_LOCATION=<enter the location where images are hosted>" >> ${work_dir}/ibm-concert-manage.env
  echo "# export PRIVATE_IMAGE_REGISTRY_PULL_USER=<enter the username of a user that can pull images from the image registry>" >> ${work_dir}/ibm-concert-manage.env
  echo "# export PRIVATE_IMAGE_REGISTRY_PULL_PASSWORD=<enter the password of the user that can pull the images from the image registry>" >> ${work_dir}/ibm-concert-manage.env

}

# Function to execute a command
function execute_command {
    echo "Executing command: $1"
    eval $1 "${@:2}"
}

# Function to run other commands
function run-sub-command {

    ${dockerexe} exec $container_name "$@"

}

# Function to initialize
function initialize {
    imageAndTag=($(echo $docker_image | tr ":" "\n"))

    ${dockerexe} rm --force ${container_name} 2>/dev/null
    ${dockerexe} rm --force ${tools_container_name} 2>/dev/null
    
    utilsImageIds=($(${dockerexe} images --sort "created" | grep ${container_name} | awk '{print $3}'))
    utilsImageTags=($(${dockerexe} images --sort "created" | grep ${container_name} | awk '{print $2}'))
    for i in ${!utilsImageTags[@]}; do
        if [ "${imageAndTag[1]}" != "${utilsImageTags[$i]}" ]
        then
        ${dockerexe} rmi --force "${utilsImageIds[$i]}"
        fi
    done

    toolsImageTags=($(${dockerexe} images --sort "created" | grep ${tools_container_name} | awk '{print $2}'))
    toolsImageIds=($(${dockerexe} images --sort "created" | grep ${tools_container_name} | awk '{print $3}'))
    for i in ${!toolsImageTags[@]}; do
        if [ "${imageAndTag[1]}" != "${toolsImageTags[$i]}" ]
        then
        ${dockerexe} rmi --force "${toolsImageIds[$i]}"
        fi
    done

    set -e
    echo ===== work_dir is ${work_dir} =====
    mkdir -p ${work_dir}
    chmod 777 ${work_dir}
    ${dockerexe} run --name ${container_name} -v "${work_dir}":/tmp/work:z -d ${docker_image}
    ${dockerexe} logs ${container_name}
    printf "to check on things:- \n ${dockerexe} exec -ti ${container_name} bash   \n   "
    create_env_file
}

# Function to login-to-ocp
function login-to-ocp {
    echo "login-to-ocp.."
    ${dockerexe} exec $container_name oc login "$@" --insecure-skip-tls-verify=true
    ${dockerexe} exec $container_name oc project
}

# Function to install
function install {
    echo "install.."
    echo "apply-olm"
    ${dockerexe} exec $container_name /opt/ansible/bin/olm-apply --release=${release} --case_download=true --components=${components} --cpd_operator_ns=${PROJECT_OPERATOR} -vvv --param-file=/tmp/work/param.yaml   # param file will be removed before release
    echo "apply-cr"
    ${dockerexe} exec $container_name /opt/ansible/bin/cr-apply --release=${release} --components=${components} --cpd_operator_ns=${PROJECT_OPERATOR} --cpd_instance_ns=${PROJECT_INSTANCE} --block_storage_class=${STG_CLASS_BLOCK} --file_storage_class=${STG_CLASS_FILE} "$@"  # Scale config?
}

# Function to check status
function status {
    echo "status.."
    ${dockerexe} exec $container_name /opt/ansible/bin/get-cr-status "$@"
}

# Function to collect state
function collect-state {
    echo "collect-state.."
    ${dockerexe} exec $container_name /opt/ansible/bin/collect-state "$@"
}

function add-cred-to-global-pull-secret {
    echo "add-cred-to-global-pull-secret"
    ${dockerexe} exec $container_name /opt/ansible/bin/add-cred-to-global-pull-secret "$@"
}

function add-icr-cred-to-global-pull-secret {
    echo "add-icr-cred-to-global-pull-secret"
    ${dockerexe} exec $container_name /opt/ansible/bin/add-icr-cred-to-global-pull-secret "$@"
}

function get-olm-artifacts {
    echo "get-olm-artifacts"
    ${dockerexe} exec $container_name /opt/ansible/bin/get-olm-artifacts --cpd_instance_ns=${PROJECT_INSTANCE}
}

function get-cr-status {
    echo "get-cr-status"
    ${dockerexe} exec $container_name /opt/ansible/bin/get-cr-status --cpd_instance_ns=${PROJECT_INSTANCE}
}

# get cpd login credentials
function get-cpd-instance-details {
    echo "get-cpd-instance-details"
    ${dockerexe} exec $container_name /opt/ansible/bin/get-cpd-instance-details --cpd_instance_ns=${PROJECT_INSTANCE} --get_admin_initial_credentials=true
}

function get-concert-instance-details {
    echo "get-concert-instance-details"
    cpd_creds=`${dockerexe} exec $container_name /opt/ansible/bin/get-cpd-instance-details --cpd_instance_ns=${PROJECT_INSTANCE} --get_admin_initial_credentials=true`
    echo $cpd_creds | sed 's/CPD/Concert/g'
}

function apply-cluster-components {
    echo "apply-cluster-components"
    ${dockerexe} exec $container_name /opt/ansible/bin/apply-cluster-components --release=${release} --license_acceptance=true
}

function authorize-instance-topology {
    echo "authorize-instance-topology"
    ${dockerexe} exec $container_name /opt/ansible/bin/authorize-instance-topology --cpd_operator_ns=${PROJECT_OPERATOR} --cpd_instance_ns=${PROJECT_INSTANCE}
}

function setup-instance-topology {
    echo "authorize-instance-topology"
    ${dockerexe} exec $container_name /opt/ansible/bin/setup-instance-topology --release=${release} --cpd_operator_ns=${PROJECT_OPERATOR} --cpd_instance_ns=${PROJECT_INSTANCE} --license_acceptance=true 
}

function delete-cr {
    echo "delete-cr"
    ${dockerexe} exec $container_name /opt/ansible/bin/delete-cr --cpd_instance_ns=${PROJECT_INSTANCE} --components=${components}

}

function delete-olm-artifacts {
    echo "delete-olm-artifacts"
    ${dockerexe} exec $container_name /opt/ansible/bin/delete-olm-artifacts --cpd_operator_ns=${PROJECT_OPERATOR} --components=${components}

}

function login-private-registry {
    echo "login-private-registry"
    ${dockerexe} exec $container_name /opt/ansible/bin/login-private-registry ${PRIVATE_REGISTRY_LOCATION} ${PRIVATE_REGISTRY_PUSH_USER} ${PRIVATE_REGISTRY_PUSH_PASSWORD}
}

function login-private-image-registry {
    echo "login-private-image-registry"
    ${dockerexe} exec $container_name /opt/ansible/bin/login-private-registry ${PRIVATE_IMAGE_REGISTRY_LOCATION} ${PRIVATE_IMAGE_REGISTRY_PULL_USER} ${PRIVATE_IMAGE_REGISTRY_PULL_PASSWORD}
}

function list-images {
    echo "list-images"
     ${dockerexe} exec $container_name /opt/ansible/bin/list-images --components=${components} --release=${release} --inspect_source_registry=true
}

function list-images-mirrored {
    echo "list-images-mirrored"
     ${dockerexe} exec $container_name /opt/ansible/bin/list-images --components=${components} --release=${release} --target_registry=${PRIVATE_REGISTRY_LOCATION} --case_download=false
}

function mirror-images {
    echo "mirror-images"
    ${dockerexe} exec $container_name /opt/ansible/bin/mirror-images --components=${components} --release=${release} --target_registry=${PRIVATE_REGISTRY_LOCATION} --case_download=false
}

function create-service-config {
    echo "create-service-config"
    ${dockerexe} exec $container_name create-service-config  --service_name=${service_name} --service_version=${service_version} --operator_ns=${PROJECT_OPERATOR} --registry_location=${PRIVATE_REGISTRY_LOCATION}
}


function concert-setup {
    echo "concert-setup"
    ${dockerexe} exec $container_name concert-setup --action=${action} --release=${release} --license_acceptance=true --operator_ns=${PROJECT_OPERATOR} --operand_ns=${PROJECT_INSTANCE} --preview=${preview} --components=${components} --service_name=${service_name} --service_version=${service_version} --block_storage_class=${STG_CLASS_BLOCK} --file_storage_class=${STG_CLASS_FILE} --registry_location=${PRIVATE_REGISTRY_LOCATION}
}

function print-help {

    ${dockerexe} exec $container_name help-utils.sh

}

case "$1" in
    execute)
        execute_command "$2" "${@:3}"
        ;;
    initialize)
        initialize
        ;;
    login-to-ocp)
        login-to-ocp "${@:2}"
        ;;
    install)
        install "${@:2}"
        ;;
    status)
        status "${@:2}"
        ;;
    collect-state)
        collect-state "${@:2}"
        ;;
    add-cred-to-global-pull-secret)
        add-cred-to-global-pull-secret "${@:2}"
        ;;
    add-icr-cred-to-global-pull-secret)
        add-icr-cred-to-global-pull-secret "${@:2}"
        ;;
    get-olm-artifacts)
        get-olm-artifacts
        ;;
    get-cr-status)
        get-cr-status
        ;;
    get-cpd-instance-details)
        get-cpd-instance-details
        ;;
    apply-cluster-components)
        apply-cluster-components
        ;;
    authorize-instance-topology)
        authorize-instance-topology
        ;;
    setup-instance-topology)
        setup-instance-topology
        ;;
    delete-cr)
        delete-cr
        ;;
    delete-olm-artifacts)
        delete-olm-artifacts
        ;;
    login-private-registry)
        login-private-registry
        ;;
    list-images)
        list-images
        ;;
    mirror-images)
        mirror-images
        ;;
    login-private-image-registry)
        login-private-image-registry
        ;;
    list-images-mirrored)
        list-images-mirrored
        ;;
    create-service-config)
        create-service-config
        ;;
    concert-setup)
        concert-setup
        ;;
    get-concert-instance-details)
        get-concert-instance-details
        ;;
    help )
        print-help
        ;;
    *)
        run-sub-command $@
esac
