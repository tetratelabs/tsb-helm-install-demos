# TSB demo install using Helm

## Deploying TSB Management Plane

Please refer for more details over here: https://docs.tetrate.io/service-bridge/latest/en-us/setup/requirements-and-download, https://docs.tetrate.io/service-bridge/latest/en-us/setup/helm/managementplane

### Prepare the required certificates using OpenSSL on Linux (Mac OS X OpenSSL is not supported)

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




## Connect to Management Plane

### Lookup and register FQDN to proceed with the Application Cluster Onboarding

### Connect using `tctl`

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
❯ tctl get org
NAME       DISPLAY NAME    DESCRIPTION
tetrate    tetrate
```

## Onboarding Application Cluster into TSB Service Mesh, i.e. Control Plane Deployment on the target cluster

Please refer for more details over here: https://docs.tetrate.io/service-bridge/latest/en-us/setup/requirements-and-download, https://docs.tetrate.io/service-bridge/latest/en-us/setup/helm/controlplane

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

## Install custom ca certificate for istiod for cross-cluster connectivity

Please refer to more details: https://tetrate.io/blog/how-are-certificates-managed-in-istio/

```sh
kubectl create secret generic cacerts -n istio-system \
  --from-file=ca-cert.pem="${FOLDER}/istiod_intermediate_ca.crt" \
  --from-file=ca-key.pem="${FOLDER}/istiod_intermediate_ca.key" \
  --from-file=root-cert.pem="${FOLDER}/ca.crt" \
  --from-file=cert-chain.pem="${FOLDER}/istiod_intermediate_ca.crt"  
```
