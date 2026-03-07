#!/bin/bash

set -e

NAMESPACE=chaos-mesh
EXPERIMENT=cpu-memory-stress.yaml


echo "Applying Chaos Experiment..."
oc apply -f $EXPERIMENT


echo "Verifying Chaos Experiment status..."
oc get stresschaos -n $NAMESPACE


echo "Chaos experiment successfully triggered"