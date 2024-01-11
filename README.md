# TSB Demo Helm Installation

## Tetrate Service Bridge (TSB) 1.8.X
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
export TSB_FQDN="r18xhelm.sandbox.tetrate.io"
export ORG="tetrate"
export VERSION="1.8.0"
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
export VERSION="1.8.0"
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
mp      tsb             1               2024-01-11 21:18:10.768315 -0400 EDT    deployed        managementplane-1.8.0   1.8.0    

> kubectl get pod -n tsb
NAME                                           READY   STATUS      RESTARTS   AGE
central-586695f45f-v68g8                       1/1     Running     0          22s
elasticsearch-0                                1/1     Running     0          3m30s
envoy-5d8d8d9656-gcn68                         1/1     Running     0          79s
envoy-5d8d8d9656-lwm5x                         1/1     Running     0          79s
iam-8d69d4c4c-gdcgt                            1/1     Running     0          79s
ldap-64bd7d7c8d-jd25q                          1/1     Running     0          3m31s
mpc-c4f64dcfb-tmdbn                            1/1     Running     0          79s
oap-7b7d89f86b-7x6z6                           1/1     Running     0          79s
otel-collector-5f85668c85-qg7xk                1/1     Running     0          79s
postgres-54589fcf97-rschw                      1/1     Running     0          3m31s
teamsync-first-run-4h6mc                       0/1     Completed   0          79s
tsb-75545fc964-6vdfj                           1/1     Running     0          79s
tsb-operator-management-plane-cb94ddcb-24p48   1/1     Running     0          4m19s
web-5899b6cbcb-9658h                           1/1     Running     0          79s
xcp-operator-central-76b8cb66ff-mgft8          1/1     Running     0          79s
❯ kubectl -n tsb  get service envoy -o=jsonpath="{.status.loadBalancer.ingress[0]['hostname','ip']}"
34.82.201.78
```
## Connect using `tctl`

> https://docs.tetrate.io/service-bridge/reference/cli/guide/index

After downloading the version for your OS, please run the command 'tctl version' to verify you have 1.8.0.

```sh
export TSB_FQDN="r18xhelm.sandbox.tetrate.io"
export ADMIN_PASSWORD="Tetrate123"


# Consult docs on how to install https://docs.tetrate.io/service-bridge/reference/cli/guide/index#installation
# export VERSION="1.8.0"
# export DISTRO="linux-amd64"
# curl -Lo "/usr/local/bin/tctl" "https://binaries.dl.tetrate.io/public/raw/versions/$DISTRO-$VERSION/tctl"
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
TCTL version: v1.8.0
TSB version: v1.8.0
❯ tctl get org
NAME       DISPLAY NAME    DESCRIPTION
tetrate    tetrate
```

## Onboarding Application Cluster into TSB Service Mesh, i.e. Control Plane Deployment on the target cluster

Please refer to [Requirements and Download Page](https://docs.tetrate.io/service-bridge/setup/requirements-and-download) and [Deploying TSB Control Plane using Helm](https://docs.tetrate.io/service-bridge/setup/helm/controlplane)

### Prepare Helm values for Control Plane installation the `controlplane_values.yaml`

```sh
export FOLDER="."
export TSB_FQDN="r18xhelm.sandbox.tetrate.io"
export REGISTRY="gcr.io/swlab18-cwli-1"
export ORG="tetrate"
export CLUSTER_NAME="app-cluster1"
export VERSION="1.8.0"
./prep_controlplane_values.sh
cat "${CLUSTER_NAME}-controlplane_values.yaml"
```

### Proceed with Control Plane installation using Helm

```sh
helm repo add tetrate-tsb-helm 'https://charts.dl.tetrate.io/public/helm/charts/'
helm repo update
helm install cp tetrate-tsb-helm/controlplane -n istio-system \
  --create-namespace -f "${CLUSTER_NAME}-controlplane_values.yaml" \
  --version $VERSION --devel
```

### Validate installation

```sh
❯ helm ls -A
NAME	NAMESPACE   	REVISION	UPDATED                               	STATUS  	CHART                	APP VERSION
cp  	istio-system	1       	2024-01-11 21:28:13.216254 -0400 -0400	deployed	controlplane-1.8.0   	1.8.0

❯ kubectl get pod -n istio-system
NAME                                                     READY   STATUS    RESTARTS     AGE
edge-7c9846f7cd-jvgn6                                    1/1     Running   0            2m7s
istio-operator-6bdbbc6c8c-g7gx8                          1/1     Running   0            2m8s
istio-operator-prod-stable-6b45d44bd8-gd569              1/1     Running   0            2m8s
istio-system-custom-metrics-apiserver-845fd8ccd4-mbpdn   1/1     Running   0            2m22s
istiod-6999bf6c64-k949j                                  1/1     Running   0            109s
istiod-prod-stable-6f6cdd8574-d9np2                      1/1     Running   0            110s
oap-deployment-6bd4bd8797-r72n9                          3/3     Running   0            90s
onboarding-operator-77899d59f4-dhgph                     1/1     Running   1 (2m ago)   2m22s
otel-collector-76b7bdcb55-gsm9s                          2/2     Running   0            2m22s
tsb-operator-control-plane-6898d66f74-nd7wh              1/1     Running   0            2m56s
vmgateway-7d45b7fc99-bgpqn                               1/1     Running   0            101s
wasmfetcher-55487bf44d-b2flb                             1/1     Running   0            2m22s
xcp-operator-edge-694dc77c55-dn87j                       1/1     Running   0            2m22s

❯  tctl x  status cluster app-cluster1 -o yaml
apiVersion: api.tsb.tetrate.io/v2
kind: ResourceStatus
metadata:
  name: app-cluster1
  organization: tetrate
spec:
  configEvents:
    events:
    - etag: '"qbSWRU3JzZQ="'
      timestamp: "2024-01-11T01:27:35.724676312Z"
      type: XCP_ACCEPTED
    - etag: '"qbSWRU3JzZQ="'
      timestamp: "2024-01-11T01:27:35.679592291Z"
      type: MPC_ACCEPTED
    - etag: '"qbSWRU3JzZQ="'
      timestamp: "2024-01-11T01:27:34.287485286Z"
      type: TSB_ACCEPTED
  message: Cluster onboarded
  status: READY
```
