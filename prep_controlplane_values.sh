#!/bin/bash

tctl install cluster-service-account  --cluster ${CLUSTER_NAME}
tctl x cluster-install-template $CLUSTER_NAME > ${CLUSTER_NAME}-controlplane_values.yaml

Externalize Secrets
export CA_CERT=`cat ca.crt`
kubectl create namespace istio-system
kubectl create secret generic mp-certs -n istio-system \
  --from-literal=ca.crt="$CA_CERT"
# es-certs
kubectl create secret generic es-certs -n istio-system \
  --from-literal=ca.crt="$CA_CERT"
