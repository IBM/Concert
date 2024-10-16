# Create one 1PL "artifact" for every image deployed by the pipeline.
#
# Note: All images deployed by the pipeline will be discovered by artifact key
#
if [[ 0 != $(get_env concert-version 0) ]]; then
  IMAGE_PURL=${IMAGE%@*}
  IMAGE_REGISTRY_PATH=${IMAGE_PURL%:*}
  save_artifact concert_deploy_$(date -u "+%Y%m%d%H%M%S") \
    "type=concert_deploy" \
    "name=${IMAGE_REGISTRY_PATH##*/}" \
    "deployment_build_number=${BUILD_NUMBER}" \
    "env_platform=${ENV_PLATFORM}" \
    "k8_platform=${K8_PLATFORM}" \
    "cluster_id=$(kubectl get ns kube-system -o jsonpath='{.metadata.uid}')" \
    "cluster_region=${CLUSTER_REGION}" \
    "cluster_name=${CLUSTER_NAME}" \
    "cluster_namespace=${CLUSTER_NAMESPACE}" \
    "app_url=${APP_URL}"
fi
