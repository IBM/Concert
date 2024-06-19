# IBM  Concert Manage Script

The Red Hat OpenShift Container Platform cluster installation is the most scalable and flexible option, where Concert is deployed on a Kubernetes cluster, providing a highly available and fault-tolerant infrastructure.

The benefits of this installation method includes high scalability and flexibility, strong high-availability options, and secure management with multiple tenants in a shared cluster.

The IBM Concert manage script (ibm-concert-manage.sh) is a command line interface designed to help users install IBM Concert on a OCP cluster. The script can be downloaded from `/manage` directory. <br>
The commands provided in this script will allow the user to perform the following functions:
- Download the necessary utils container which in turn will be used to perform other tasks to help with Concert installation
- Update global image pull secrets
- Setup concert operators and operands

## More detials 
[How to install IBM Concert on OCP Cluster](https://www.ibm.com/docs/en/concert?topic=premises-installing-concert-openshift)

