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
  tag: $VERSION
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
    port: 443
    selfSigned: true
  meshExpansion: {}
  telemetryStore:
    elastic:
      host: $TSB_FQDN
      port: 443
      protocol: https
      selfSigned: true
      version: 7
  components:
    xcp:
      centralAuthMode: JWT
      centralProvidedCaCert: true 
      configProtection: {}
      isolationBoundaries:
      - name: global
        revisions:
        - name: default
          istio:
            tsbVersion: $VERSION
        - name: canary
          istio:
            tsbVersion: $VERSION
      kubeSpec:
        deployment:
          env:
            - name: ENABLE_GATEWAY_DELETE_HOLD
              value: "true"
            - name: GATEWAY_DELETE_HOLD_SECONDS
              value: "20"
        overlays:
          - apiVersion: install.xcp.tetrate.io/v1alpha1
            kind: EdgeXcp
            name: edge-xcp
            patches:
              - path: spec.components.edgeServer.kubeSpec.deployment.env[-1]
                value:
                  name: ENABLE_ENHANCED_EAST_WEST_ROUTING
                  value: "true"
              - path: spec.components.edgeServer.kubeSpec.deployment.env[-1]
                value:
                  name: DISABLE_TIER1_TIER2_SEPARATION
                  value: "true"
              - path: spec.components.edgeServer.kubeSpec.deployment.env[-1]
                value:
                  name: ENABLE_DNS_RESOLUTION_AT_EDGE
                  value: "true"
              - path: spec.components.edgeServer.kubeSpec.deployment.env[-1]
                value:
                  name: ENABLE_NETWORK_POLICY_TRANSLATION
                  value: "false"
              - path: spec.components.edgeServer.kubeSpec.deployment.env[-1]
                value:
                  name: ENABLE_NON_INGRESS_HOST_LEVEL_AUTHORIZATION
                  value: "false"
    gitops:
      enabled: true
      reconcileInterval: 60s
    oap:
      streamingLogEnabled: true
    meshObservability:
      settings:
        apiEndpointMetricsEnabled: true  
operator:
  deployment:
    env:
    - name: ISTIO_ISOLATION_BOUNDARIES
      value: "true"
EOF