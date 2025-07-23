Concert is available as a software-as-a-service (SaaS) or as an on-premises solution. Multiple on-premises deployment options are available, including that uses Red Hat® OpenShift® Container Platform (with or without CPFS), deploying on Amazon Elastic Kubernetes Service (EKS), or deploying to a virtual machine (VM).
This repo provides the packages for installing Concert on Kuberenetes and Virtual Machine.  

# IBM  Concert developer package for virtual machine


IBM® Concert provides a package with a set of containerized services that you can run on a Linux machine. The package includes scripts and utilities for you to set up and operate the Concert services.

The virtual machine deployment is intended for starter use cases, and for ease of deployment and management.  With the single node installation, resiliency is limited and host node failures will result in Concert being inaccessible. Enterprise features such as Identity Provider integration is not supported in this configuration and may only be suitable for non-production use.  

Extract the file `ibm-concert.tar.gz` and follow the [instructions](https://www.ibm.com/docs/en/concert?topic=premises-installing-concert-virtual-machine) to deploy Concert on a virtual machine.

# IBM  Concert developer package for Kuberentes Cluster like OCP or EKS 


IBM® Concert provides a package with a scripts that you can be run on a workstation to install Concert on your EKS or OCP Cluster. The package includes scripts and utilities for you to set up and operate the Concert services. 
Extract the file `ibm-concert-k8s.tgz` and follow the [instructions](https://www.ibm.com/docs/en/concert?topic=started-deployment-options) to deploy Concert on your EKS or OCP cluster. This is non-CPFS version of OCP. If CPFS is to be installed follow the [instructions](https://www.ibm.com/docs/en/concert?topic=started-deployment-options) specific for CPFS.
