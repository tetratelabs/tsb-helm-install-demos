#!/bin/bash

# awk cmd taken from https://www.starkandwayne.com/blog/bashing-your-yaml/

cat << EOF > "$FOLDER/cluster-$CLUSTER_NAME.yaml"
---
apiVersion: api.tsb.tetrate.io/v2
kind: Cluster
metadata:
  name: $CLUSTER_NAME
  organization: $ORG
spec:
  tokenTtl: "87600h"
  tier1Cluster: ${TIER1:-false}
EOF

tctl apply -f "$FOLDER/cluster-$CLUSTER_NAME.yaml"

tctl install cluster-service-account --cluster $CLUSTER_NAME > $CLUSTER_NAME-service-account.jwk

cat << EOF > "$FOLDER/$CLUSTER_NAME-controlplane_values.yaml"
image:
  registry: $REGISTRY
  tag: 1.5.2
secrets:
  clusterServiceAccount:
    JWK: '$(cat $CLUSTER_NAME-service-account.jwk)'
    clusterFQN: organizations/$ORG/clusters/$CLUSTER_NAME
  elasticsearch:
    cacert: |
$(awk '{printf "      %s\n", $0}' < ca.crt)
  tsb:
    cacert: |  
$(awk '{printf "      %s\n", $0}' < ca.crt)
  xcp: 
    rootca: |
$(awk '{printf "      %s\n", $0}' < ca.crt)
spec:
  hub: $REGISTRY
  managementPlane:
    clusterName: $CLUSTER_NAME
    host: $TSB_FQDN
    port: 8443
    selfSigned: true
  meshExpansion: {}
  telemetryStore:
    elastic:
      host: $TSB_FQDN
      port: 8443
      protocol: https
      selfSigned: true
      version: 7
EOF

cat << EOF > "$FOLDER/dataplane_values.yaml"
image:
  registry: $REGISTRY
  tag: 1.5.2
EOF
