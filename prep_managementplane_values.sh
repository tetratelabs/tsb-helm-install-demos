#!/bin/bash

# awk cmd taken from https://www.starkandwayne.com/blog/bashing-your-yaml/

cat >"$FOLDER/managementplane_values.yaml" <<EOF
image:
  registry: $REGISTRY
  tag: $VERSION
secrets:
  tsb:
    adminPassword: $ADMIN_PASSWORD
    cert: |   
$(awk '{printf "      %s\n", $0}' < tsb_certs.crt)
    key: |  
$(awk '{printf "      %s\n", $0}' < tsb_certs.key)
  xcp:
    autoGenerateCerts: false
    central:
      cert: |   
$(awk '{printf "        %s\n", $0}' < xcp-central-cert.crt)
      key: |  
$(awk '{printf "        %s\n", $0}' < xcp-central-cert.key)
    rootca: |
$(awk '{printf "      %s\n", $0}' < ca.crt)
spec:
  certIssuer:
    selfSigned: {}
    clusterIntermediateCAs: {}
  hub: $REGISTRY
  organization: $ORG
  components:
    frontEnvoy:
      port: 443
EOF
