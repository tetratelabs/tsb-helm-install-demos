# TSB Demo Helm Installation

## Tetrate Service Bridge (TSB)
Review the TSB components in the docs [here](https://docs.tetrate.io/service-bridge/setup/components). This page will explain in details TSB components and external dependencies that you have to provision and connect to be able to run TSB.

## Firewall Rules Requirements
Review [Firewall Information](https://docs.tetrate.io/service-bridge/setup/firewall_information) page for the required ports to be opened.

> NOTE: TSB Load Balancer (also known as front-envoy) has default port 8443. This port value is user configurable. For example, we have changed the port to 443 as part of the installation process below. If the default port is changed, then all components that communicate via front-envoy need to be adjusted accordingly to match the user-defined value of the front-envoy port.

## Deploying TSB Management Plane

Please refer to [Requirements and Download Page](https://docs.tetrate.io/service-bridge/setup/requirements-and-download) and [Deploying TSB Management Plane using Helm](https://docs.tetrate.io/service-bridge/latest/en-us/setup/helm/managementplane)

### Prepare the required certificates using OpenSSL on Linux (Mac OS X OpenSSL is not supported)

Please refer to [Certificates Setup](https://docs.tetrate.io/service-bridge/setup/certificate/certificate-setup) page for more details

```sh
export FOLDER="."
export TSB_FQDN="r19xhelm.sandbox.tetrate.io"
export ORG="tetrate"
export VERSION="1.9.0"
./certs-gen/certs-gen.sh
```

The output will consist of:

- `ca.crt` - self-signed CA
- `tsb_certs.crt, tsb_certs.key` - TSB UI certificate
- `xcp-central-cert.crt, xcp-central-cert.key` - XCP Central certificate

### Prepare Helm values for Management Plane installation - `managementplane_values.yaml`

```sh
export FOLDER="."
export REGISTRY="gcr.io/r18xhelm-hqdp-1"
export ORG="tetrate"
export VERSION="1.9.0"
export ADMIN_PASSWORD="Tetrate123"
./prep_managementplane_values.sh
cat managementplane_values.yaml
```

### Deploy TSB Management Plane using Helm

```sh
helm repo add tetrate-tsb-helm 'https://charts.dl.tetrate.io/public/helm/charts/'
helm repo update
helm install mp tetrate-tsb-helm/managementplane -n tsb \
  --create-namespace -f managementplane_values.yaml \
  --version $VERSION --devel  
```

### Validate TSB Management Plane installation and register FQDN to proceed with the Application Cluster Onboarding

```sh
❯ helm ls -A
NAME    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                   APP VERSION
mp      tsb             1               2024-04-05 16:08:58.131719 -0400 EDT    deployed        managementplane-1.9.0-internal-rc5      1.9.0 

> kubectl get pod -n tsb
NAME                                             READY   STATUS    RESTARTS   AGE
central-6457448659-4dswj                         1/1     Running   0          99s
elastic-operator-0                               1/1     Running   0          4m22s
envoy-d8495d777-75lbw                            1/1     Running   0          3m45s
envoy-d8495d777-h7pdb                            1/1     Running   0          3m45s
iam-758f9f57c7-ptbk6                             1/1     Running   0          3m45s
kubegres-controller-manager-6b8fd84f4d-mcjr5     2/2     Running   0          4m22s
mpc-5cb59fc86b-xbgw4                             1/1     Running   0          3m44s
oap-668dc45bff-x9kvt                             1/1     Running   0          3m44s
otel-collector-6475b44bcd-sbzqd                  1/1     Running   0          3m45s
tsb-76c7866dc8-pfplr                             1/1     Running   0          3m44s
tsb-elastic-es-es-data-node-0                    1/1     Running   0          3m49s
tsb-elastic-es-es-master-node-0                  1/1     Running   0          3m49s
tsb-operator-management-plane-6c844b8dd8-4ks98   1/1     Running   0          4m46s
tsb-postgres-1-0                                 1/1     Running   0          3m48s
tsb-postgres-2-0                                 1/1     Running   0          3m19s
tsb-postgres-3-0                                 1/1     Running   0          2m19s
web-58877cf75c-lkxrp                             1/1     Running   0          3m45s
xcp-operator-central-8757f6978-rxjs4             1/1     Running   0          3m45s
❯ kubectl -n tsb  get service envoy -o=jsonpath="{.status.loadBalancer.ingress[0]['hostname','ip']}"
34.82.201.78
```
## Connect using `tctl`

> https://docs.tetrate.io/service-bridge/reference/cli/guide/index

After downloading the version for your OS, please run the command 'tctl version' to verify your version

```sh
export TSB_FQDN="r19xhelm.sandbox.tetrate.io"
export ADMIN_PASSWORD="Tetrate123"

```
Make sure you have updated your DNS with a record for TSB FQDN (`A` record or `CNAME` record of envoy service obtained previously)

```sh
tctl config clusters set helm --tls-insecure --bridge-address $TSB_FQDN:443
tctl config users set helm --username admin --password $ADMIN_PASSWORD --org $ORG
tctl config profiles set helm --cluster helm --username helm
tctl config profiles set-current helm
```

###  Perform the basic query using `tctl` to validate the connection against TSB Management Plane

```sh
❯ tctl version
TCTL version: v1.9.0
TSB version: v1.9.0
❯ tctl get org
NAME       DISPLAY NAME    DESCRIPTION
tetrate    tetrate
```

## Onboarding Application Cluster into TSB Service Mesh, i.e. Control Plane Deployment on the target cluster

Please refer to [Requirements and Download Page](https://docs.tetrate.io/service-bridge/setup/requirements-and-download) and [Deploying TSB Control Plane using Helm](https://docs.tetrate.io/service-bridge/setup/helm/controlplane)

### Prepare Helm values for Control Plane installation the `controlplane_values.yaml`

```sh
export FOLDER="."
export TSB_FQDN="r19xhelm.sandbox.tetrate.io"
export REGISTRY="gcr.io/swlab18-cwli-1"
export ORG="tetrate"
export CLUSTER_NAME="app-cluster1"
export VERSION="1.9.0"
./prep_controlplane_values.sh
cat "${CLUSTER_NAME}-controlplane_values.yaml"
```

### Proceed with Control Plane installation using Helm

```sh
helm repo add tetrate-tsb-helm 'https://charts.dl.tetrate.io/public/helm/charts/'
helm repo update
helm install cp tetrate-tsb-helm/controlplane -n istio-system \
  --create-namespace -f "${CLUSTER_NAME}-controlplane_values.yaml" \
  --version $VERSION \
  --devel \
  --set image.registry=${REGISTRY} \
  --set spec.hub=${REGISTRY}
  --set spec.managementPlane.selfSigned=true \
  --set spec.telemetryStore.elastic.selfSigned=true
```

### Validate installation

```sh
❯ helm ls -A
NAME    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                           APP VERSION       
cp      istio-system    1               2024-04-11 14:21:54.634675 -0400 EDT    deployed        controlplane-1.9.0 1.9.0

❯ kubectl get pod -n istio-system
NAME                                                     READY   STATUS    RESTARTS   AGE
edge-6dcf648ddc-ngkqv                                    1/1     Running   0          53m
istio-operator-6c7589658b-ctwsp                          1/1     Running   0          64m
istio-system-custom-metrics-apiserver-7479b7d8c6-b9svg   1/1     Running   0          64m
istiod-6c599bd8d8-75cgx                                  1/1     Running   0          64m
oap-deployment-59597d4d6f-j2rks                          3/3     Running   0          7m27s
onboarding-operator-59cffcc54c-zl6cq                     1/1     Running   0          64m
otel-collector-5cf47879db-75jvd                          2/2     Running   0          64m
tsb-operator-control-plane-749854cdc9-h4dgb              1/1     Running   0          57m
wasmfetcher-b6c5f4988-hwfvs                              1/1     Running   0          64m
xcp-operator-edge-c46b977db-5kvc4                        1/1     Running   0          54m

❯  tctl x  status cluster app-cluster1 -o yaml
apiVersion: api.tsb.tetrate.io/v2
kind: ResourceStatus
metadata:
  name: app-cluster1
  organization: tetrate
spec:
  configEvents:
    events:
    - etag: '"qSzR7gvoORQ="'
      timestamp: "2024-04-11T13:44:37.860801302Z"
      type: XCP_ACCEPTED
    - etag: '"qSzR7gvoORQ="'
      timestamp: "2024-04-11T13:44:37.830274023Z"
      type: MPC_ACCEPTED
    - etag: '"qSzR7gvoORQ="'
      timestamp: "2024-04-11T13:44:33.341066660Z"
      type: TSB_ACCEPTED
  message: Cluster onboarded
  status: READY
```
