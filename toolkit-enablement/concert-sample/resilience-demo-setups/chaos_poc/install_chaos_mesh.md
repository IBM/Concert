## Chaos Mesh Installation on OpenShift (OCP)

## Prerequisites
1. OpenShift cluster (4.x)
2. oc CLI installed and logged in as cluster-admin
3. helm installed

Steps
# Create namespace
oc create ns chaos-mesh

# Add Chaos Mesh Helm repo
helm repo add chaos-mesh https://charts.chaos-mesh.org
helm repo update

# Install Chaos Mesh
helm install chaos-mesh chaos-mesh/chaos-mesh \
-n chaos-mesh \
--set dashboard.create=true \
--set chaosDaemon.runtime=containerd \
--set chaosDaemon.socketPath=/var/run/crio/crio.sock

# Verify installation
oc get pods -n chaos-mesh

# Expose Chaos Dashboard (OCP Route)
oc expose svc chaos-dashboard -n chaos-mesh
oc get route -n chaos-mesh

Open the generated route URL in the browser

# create a token for the RBAC Authorization
oc create token chaos-dashboard -n chaos-mesh