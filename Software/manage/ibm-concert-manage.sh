#!/bin/bash
set -e

scriptdir=`dirname $0`
cd ${scriptdir}
scriptdir=`pwd`
dockerexe=${DOCKER_EXE:-podman}
docker_image=${UTILS_IMG:-"icr.io/cpopen/ibm-aaf-utils:1.0.3"}
work_dir=${WORK_DIR:-"${scriptdir}/.ibm-concert-manage-utils"}

container_name=ibm-aaf-utils
release=${RELEASE:-"5.0.3"} # AAF Release
components=${COMPONENTS:-"concert"} 
service_name=concert
service_version=${SERVICE_VERSION:-"1.0.3"} # Concert Release
preview=${PREVIEW:-"false"}
action=${ACTION:-"install"}
registry_location=${PRIVATE_REGISTRY_LOCATION:-"cp.icr.io"}
registry_location="${registry_location}/cp/concert"
case_download=${CASE_DOWNLOAD:-true}

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
    
    utilsImageIds=($(${dockerexe} images --sort "created" | grep ${container_name} | awk '{print $3}'))
    utilsImageTags=($(${dockerexe} images --sort "created" | grep ${container_name} | awk '{print $2}'))
    for i in ${!utilsImageTags[@]}; do
        if [ "${imageAndTag[1]}" != "${utilsImageTags[$i]}" ]
        then
        ${dockerexe} rmi --force "${utilsImageIds[$i]}"
        fi
    done

    set -e
    echo ===== work_dir is ${work_dir} =====
    mkdir -p ${work_dir}
    chmod 777 -R ${work_dir}
    export DOCKER_DEFAULT_PLATFORM="linux/amd64"
    if [ "${dockerexe}" == "podman" ]
    then
        ${dockerexe} run --arch=amd64 --name ${container_name} -v "${work_dir}":/tmp/work:z -d ${docker_image}
    else
        ${dockerexe} run --name ${container_name} -v "${work_dir}":/tmp/work:z -d ${docker_image}
    fi
    
    ${dockerexe} logs ${container_name}
    printf "to check on things:- \n ${dockerexe} exec -ti ${container_name} bash   \n   "
}

# Function to login-to-ocp
function login-to-ocp {
    echo "login-to-ocp.."
    ${dockerexe} exec $container_name oc login "$@" --insecure-skip-tls-verify=true
    ${dockerexe} exec $container_name oc project
}

# Function to install concert
function install {
    echo "install.."
    echo "apply-olm"
    ${dockerexe} exec $container_name apply-olm --release=${release} --case_download=${case_download} --components=${components} --cpd_operator_ns=${PROJECT_OPERATOR}
    echo "create-service-config"
    ${dockerexe} exec $container_name create-service-config --service_name=${service_name} --service_version=${service_version} --operator_ns=${PROJECT_OPERATOR} --registry_location=${registry_location}
    echo "apply-cr"
    ${dockerexe} exec $container_name apply-cr --release=${release} --components=${components} --cpd_operator_ns=${PROJECT_OPERATOR} --cpd_instance_ns=${PROJECT_INSTANCE} --block_storage_class=${STG_CLASS_BLOCK} --file_storage_class=${STG_CLASS_FILE} "$@" 
}

# Function to install zen 
function install_zen {
    echo "install zen.."
    ${dockerexe} exec $container_name apply-olm --release=${release} --case_download=${case_download} --components=zen --cpd_operator_ns=${PROJECT_OPERATOR}
    echo "apply-aaf-zen"
    ${dockerexe} exec $container_name apply_aaf_zen --operator_ns=${PROJECT_OPERATOR} --instance_ns=${PROJECT_INSTANCE}
    echo "aaf-zen-cr-apply"
    ${dockerexe} exec $container_name aaf-zen-cr-apply --instance_ns=${PROJECT_INSTANCE} --block_storage_class=${STG_CLASS_BLOCK} --service_name=${service_name} --release=${release}
}

# Function to upgrade zen 
function upgrade_zen {
    echo "upgrade zen.."
    echo "apply-aaf-zen"
    ${dockerexe} exec $container_name apply_aaf_zen --operator_ns=${PROJECT_OPERATOR} --instance_ns=${PROJECT_INSTANCE}
    echo "aaf-zen-cr-apply"
    ${dockerexe} exec $container_name aaf-zen-cr-apply --instance_ns=${PROJECT_INSTANCE} --block_storage_class=${STG_CLASS_BLOCK} --service_name=${service_name} --release=${release} --upgrade=true
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

function setup-route {
    echo "setup-route"
    ${dockerexe} exec $container_name /opt/ansible/bin/setup-route "$@"
}

function get-olm-artifacts {
    echo "get-olm-artifacts"
    ${dockerexe} exec $container_name /opt/ansible/bin/get-olm-artifacts --cpd_instance_ns=${PROJECT_INSTANCE}
}

function get-cr-status {
    echo "get-cr-status"
    ${dockerexe} exec $container_name /opt/ansible/bin/get-cr-status --cpd_instance_ns=${PROJECT_INSTANCE}
}

function get-concert-instance-details {
    echo "get-concert-instance-details"
    ${dockerexe} exec $container_name get-concert-instance-details --instance_ns=${PROJECT_INSTANCE} --get_admin_initial_credentials=true
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
    echo "setup-instance-topology"
    ${dockerexe} exec $container_name /opt/ansible/bin/setup-instance-topology --release=${release} --cpd_operator_ns=${PROJECT_OPERATOR} --cpd_instance_ns=${PROJECT_INSTANCE} --license_acceptance=true --block_storage_class=${STG_CLASS_BLOCK}
}

function delete-cr {
    echo "delete-cr"
    ${dockerexe} exec $container_name /opt/ansible/bin/delete-cr --cpd_instance_ns=${PROJECT_INSTANCE} --components=${components}

}

function delete-olm-artifacts {
    echo "delete-olm-artifacts"
    ${dockerexe} exec $container_name /opt/ansible/bin/delete-olm-artifacts --cpd_operator_ns=${PROJECT_OPERATOR} --components=${components}

}

function login-entitled-registry {
    echo "login-entitled-registry"
    ${dockerexe} exec $container_name /opt/ansible/bin/login-entitled-registry ${IBM_ENTITLEMENT_KEY}
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

function mirror-images-from-intermediate {
    echo "mirror-images-from-intermediate"
    ${dockerexe} exec $container_name /opt/ansible/bin/mirror-images --components=${components} --release=${release} --source_registry=127.0.0.1:12443 --target_registry=${PRIVATE_REGISTRY_LOCATION} --case_download=false
}
function apply-aaf-icsp {
    echo "apply-aaf-icsp"
    ${dockerexe} exec $container_name apply-aaf-icsp --registry=${PRIVATE_REGISTRY_LOCATION}
}

function create-service-config {
    echo "create-service-config"
    ${dockerexe} exec $container_name create-service-config  --service_name=${service_name} --service_version=${service_version} --operator_ns=${PROJECT_OPERATOR} --registry_location=${registry_location}
    
}

function concert-setup {
    echo "concert-setup"
    ${dockerexe} exec $container_name concert-setup --action=${action} --release=${release} --license_acceptance=true --operator_ns=${PROJECT_OPERATOR} --operand_ns=${PROJECT_INSTANCE} --preview=${preview} --components=${components} --service_name=${service_name} --service_version=${service_version} --block_storage_class=${STG_CLASS_BLOCK} --file_storage_class=${STG_CLASS_FILE} --registry_location=${registry_location}
    exit_status=$?
    if [  $exit_status -ne 0 ]; then
        echo "concert-setup failed"
        exit $exit_status
    fi
}

function upgrade-concert {
    echo "upgrade-concert"
    ${dockerexe} exec $container_name concert-setup --action=upgrade --release=${release} --license_acceptance=true --operator_ns=${PROJECT_OPERATOR} --operand_ns=${PROJECT_INSTANCE} --preview=${preview} --components=${components} --service_name=${service_name} --service_version=${service_version} --block_storage_class=${STG_CLASS_BLOCK} --file_storage_class=${STG_CLASS_FILE} --registry_location=${registry_location}
    exit_status=$?
    if [  $exit_status -ne 0 ]; then
        echo "concert-setup upgrade failed"
        exit $exit_status
    fi
}

function case-download {
     ${dockerexe} exec $container_name case-download --components=${components}   --release=${release}
}

function delete-concert-zen-extn {
     ${dockerexe} exec $container_name delete-concert-zen-extn --instance_ns=${PROJECT_INSTANCE}
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
    install_zen)
        install_zen
        ;;
    upgrade_zen)
        upgrade_zen
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
    login-entitled-registry)
        login-entitled-registry
        ;;
    list-images)
        list-images
        ;;
    mirror-images)
        mirror-images
        ;;
    mirror-images-from-intermediate)
        mirror-images-from-intermediate
        ;;
    login-private-image-registry)
        login-private-image-registry
        ;;
    list-images-mirrored)
        list-images-mirrored
        ;;
    apply-aaf-icsp)
        apply-aaf-icsp
        ;;
    create-service-config)
        create-service-config
        ;;
    concert-setup)
        concert-setup
        ;;
    upgrade-concert)
       upgrade-concert
       ;;
    get-concert-instance-details)
        get-concert-instance-details
        ;;
    case-download)
        case-download
        ;;
    setup-route)
       setup-route
       ;;
    delete-concert-zen-extn)
       delete-concert-zen-extn
       ;;
    help )
        print-help
        ;;
    *)
        run-sub-command $@
esac
