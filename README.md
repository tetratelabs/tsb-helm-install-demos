# TSB Demo Helm Installation

## Tetrate Service Bridge (TSB) 1.6.0
Review the TSB components in the docs [here](https://docs.tetrate.io/service-bridge/1.6.x/en-us/setup/components). This page will explain in details TSB components and external dependencies that you have to provision and connect to be able to run TSB.

## Firewall Rules Requirements
Review [Firewall Information](https://docs.tetrate.io/service-bridge/1.6.x/en-us/setup/firewall_information) page for the required ports to be opened.

> NOTE: TSB Load Balancer (also known as front-envoy) has default port 8443. This port value is user configurable. For example, we have changed the port to 443 as part of the installation process below. If the default port is changed, then all components that communicate via front-envoy need to be adjusted accordingly to match the user-defined value of the front-envoy port.

## Deploying TSB Management Plane

Please refer to [Requirements and Download Page](https://docs.tetrate.io/service-bridge/latest/en-us/setup/requirements-and-download) and [Deploying TSB Management Plane using Helm](https://docs.tetrate.io/service-bridge/latest/en-us/setup/helm/managementplane)

### Prepare the required certificates using OpenSSL on Linux (Mac OS X OpenSSL is not supported)

Please refer to [Certificates Setup](https://docs.tetrate.io/service-bridge/1.6.x/en-us/setup/certificate/certificate-setup) page for more details

```sh
export FOLDER="."
export TSB_FQDN="r160helm.sandbox.tetrate.io"
export ORG="tetrate"
export VERSION="1.6.0"
./certs-gen/certs-gen.sh
```

The output will consist of:

- `ca.crt` - self-signed CA
- `tsb_certs.crt, tsb_certs.key` - TSB UI certificate
- `xcp-central-cert.crt, xcp-central-cert.key` - XCP Central certificate
- `istiod_intermediate_ca.crt` - Custom CA certificate for istiod

### Prepare Helm values for Management Plane installation - `managementplane_values.yaml`

```sh
export FOLDER="."
export REGISTRY="gcr.io/r160helm-hqdp-1"
export ORG="tetrate"
export VERSION="1.6.0"
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
NAME           	NAMESPACE   	REVISION	UPDATED                             	STATUS  	CHART                	APP VERSION
managementplane	tsb         	1       	2023-03-06 22:30:56.640144 -0500 EST	deployed	managementplane-1.6.0	1.6.0

> kubectl get pod -n tsb
NAME                                             READY   STATUS    RESTARTS        AGE
central-596fc4cfcf-dwgvf                         1/1     Running   0               3m52s
elasticsearch-0                                  1/1     Running   0               9m27s
envoy-764f68b69f-2qqq8                           1/1     Running   0               8m41s
envoy-764f68b69f-jz4zx                           1/1     Running   0               8m42s
envoy-764f68b69f-nkcdk                           1/1     Running   0               85s
iam-84c66848bc-k8s7z                             1/1     Running   0               8m42s
ldap-899b76846-rdhwv                             1/1     Running   0               9m26s
mpc-8548678f5-z2c87                              1/1     Running   6 (5m32s ago)   8m42s
oap-cc9bd8949-hxpzr                              1/1     Running   0               8m41s
otel-collector-558c64499c-hfjwt                  1/1     Running   0               8m41s
postgres-85cc4868f6-r78lt                        1/1     Running   0               9m27s
tsb-598c577f64-ndzh5                             1/1     Running   0               8m42s
tsb-operator-management-plane-5d774dc978-5h446   1/1     Running   0               9m55s
web-5b94dbb867-9dmpm                             1/1     Running   0               8m41s
xcp-operator-central-c85b549f4-zmz6w             1/1     Running   2 (4m29s ago)   8m42s

❯ kubectl -n tsb  get service envoy -o=jsonpath="{.status.loadBalancer.ingress[0]['hostname','ip']}"
20.232.52.49
```
## Connect using `tctl`

> https://docs.tetrate.io/service-bridge/1.6.x/en-us/reference/cli/guide/index

After downloading the version for your OS, please run the command 'tctl version' to verify you have 1.6.0.

```sh
export TSB_FQDN="r160helm.sandbox.tetrate.io"
export ADMIN_PASSWORD="Tetrate123"


# Consult docs on how to install https://docs.tetrate.io/service-bridge/1.6.x/en-us/setup/tctl_connect
# export VERSION="1.6.0"
# export DISTRO="linux-amd64"
# curl -Lo "/usr/local/bin/tctl" "https://binaries.dl.tetrate.io/public/raw/versions/$DISTRO-$VERSION/tctl"

tctl config clusters set helm --tls-insecure --bridge-address $TSB_FQDN:443
tctl config users set helm --username admin --password $ADMIN_PASSWORD --org $ORG
tctl config profiles set helm --cluster helm --username helm
tctl config profiles set-current helm
```

###  Perform the basic query using `tctl` to validate the connection against TSB Management Plane

```sh
❯ tctl version
TCTL version: v1.6.0-heads/tags/1.6.0
TSB version: v1.6.0
❯ tctl get org
NAME    DISPLAY NAME    DESCRIPTION
pnc     pnc
```

## Onboarding Application Cluster into TSB Service Mesh, i.e. Control Plane Deployment on the target cluster

Please refer to [Requirements and Download Page](https://docs.tetrate.io/service-bridge/latest/en-us/setup/requirements-and-download) and [Deploying TSB Control Plane using Helm](https://docs.tetrate.io/service-bridge/latest/en-us/setup/helm/controlplane)

### Prepare Helm values for Control Plane installation the `controlplane_values.yaml` and `dataplane_values.yaml`

```sh
export FOLDER="."
export TSB_FQDN="r160helm.sandbox.tetrate.io"
export REGISTRY="gcr.io/r160helm-hqdp-1"
export ORG="tetrate"
export CLUSTER_NAME="app-cluster1"
export VERSION="1.6.0"
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
helm install dp tetrate-tsb-helm/dataplane -n istio-gateway \
  --create-namespace -f dataplane_values.yaml \
  --version $VERSION --devel
```

### Install custom ca certificate for istiod for cross-cluster connectivity

Please refer for more details: https://tetrate.io/blog/how-are-certificates-managed-in-istio/

```sh
kubectl create secret generic cacerts -n istio-system \
  --from-file=ca-cert.pem="${FOLDER}/istiod_intermediate_ca.crt" \
  --from-file=ca-key.pem="${FOLDER}/istiod_intermediate_ca.key" \
  --from-file=root-cert.pem="${FOLDER}/ca.crt" \
  --from-file=cert-chain.pem="${FOLDER}/istiod_intermediate_ca.crt"  
```

### Validate installation

```sh
❯ helm ls -A
NAME        	NAMESPACE    	REVISION	UPDATED                             	STATUS  	CHART              	APP VERSION
cert-manager	cert-manager 	1       	2023-03-06 22:45:00.590569 -0500 EST	deployed	cert-manager-v1.9.2	v1.9.2
controlplane	istio-system 	1       	2023-03-06 22:56:49.229615 -0500 EST	deployed	controlplane-1.6.0 	1.6.0
dataplane   	istio-gateway	1       	2023-03-06 22:56:59.459548 -0500 EST	deployed	dataplane-1.6.0    	1.6.0

❯ kubectl get pod -n istio-system
NAME                                                     READY   STATUS    RESTARTS   AGE
edge-8569f6446b-hv4c5                                    1/1     Running   0          42s
istio-operator-79d6569c5-8qwv8                           1/1     Running   0          2m37s
istio-system-custom-metrics-apiserver-5c8d4d5576-trf2x   1/1     Running   0          2m27s
istiod-6b6db55f4-7rsgr                                   1/1     Running   0          111s
oap-deployment-5459bcffdf-tbb8m                          3/3     Running   0          102s
onboarding-operator-7854c6d999-68hw7                     1/1     Running   0          2m27s
otel-collector-689f4b8bc9-68j4d                          2/2     Running   0          2m27s
tsb-operator-control-plane-7db45c95bc-zqhf5              1/1     Running   0          3m20s
vmgateway-54794c6749-trrh7                               1/1     Running   0          111s
xcp-operator-edge-79689d5994-2nb2k                       1/1     Running   0          2m27s

❯  kubectl get pod -n istio-gateway
NAME                                       READY   STATUS    RESTARTS   AGE
istio-operator-6f668464f7-z2bv2            1/1     Running   0          2m21s
tsb-operator-data-plane-59c7bd4474-x26xv   1/1     Running   0          3m3s

❯  tctl x  status cluster app-cluster2 -o yaml
apiVersion: api.tsb.tetrate.io/v2
kind: ResourceStatus
metadata:
  name: app-cluster2
  organization: pnc
spec:
  configEvents:
    events:
    - etag: '"gZxRhi5xlo8="'
      timestamp: "2023-03-07T03:56:26.578820917Z"
      type: XCP_ACCEPTED
    - etag: '"gZxRhi5xlo8="'
      timestamp: "2023-03-07T03:56:26.548583572Z"
      type: MPC_ACCEPTED
    - etag: '"gZxRhi5xlo8="'
      timestamp: "2023-03-07T03:56:25.453170857Z"
      type: TSB_ACCEPTED
  message: Cluster onboarded
  status: READY

```