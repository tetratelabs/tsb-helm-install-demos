cat > "${FOLDER}/tsb_objects.yaml" <<EOF
---
apiVersion: api.tsb.tetrate.io/v2
kind: Tenant
metadata:
  organization: tetrate
  name: tetrate
spec:
  displayName: Tetrate
---
apiversion: api.tsb.tetrate.io/v2
kind: Workspace
metadata:
  organization: tetrate
  tenant: tetrate
  name: bookinfo-ws
spec:
  namespaceSelector:
    names:
      - "demo/bookinfo"
---
apiVersion: gateway.tsb.tetrate.io/v2
kind: Group
metadata:
  organization: tetrate
  tenant: tetrate
  workspace: bookinfo-ws
  name: bookinfo-gw
spec:
  namespaceSelector:
    names:
      - "demo/bookinfo"
  configMode: BRIDGED
---
apiVersion: traffic.tsb.tetrate.io/v2
kind: Group
Metadata:
  organization: tetrate
  tenant: tetrate
  workspace: bookinfo-ws
  name: bookinfo-traffic
spec:
  namespaceSelector:
    names:
      - "demo/bookinfo"
  configMode: BRIDGED
---
apiVersion: security.tsb.tetrate.io/v2
kind: Group
Metadata:
  organization: tetrate
  tenant: tetrate
  workspace: bookinfo-ws
  name: bookinfo-security
spec:
  namespaceSelector:
    names:
      - "demo/bookinfo"
  configMode: BRIDGED
---
apiVersion: gateway.tsb.tetrate.io/v2
kind: IngressGateway
Metadata:
  organization: tetrate
  name: bookinfo-gw-ingress
  group: bookinfo-gw
  workspace: bookinfo-ws
  tenant: tetrate
spec:
  workloadSelector:
    namespace: bookinfo
    labels:
      app: tsb-gateway-bookinfo
  http:
    - name: bookinfo
      port: 8443
      hostname: "bookinfo.tetrate.com"
      tls:
        mode: SIMPLE
        secretName: bookinfo-certs
      routing:
        rules:
          - route:
              host: "bookinfo/productpage.bookinfo.svc.cluster.local"
EOF

tctl apply -f "${FOLDER}/tsb_objects.yaml" 
