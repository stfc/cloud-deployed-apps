# App Setup Steps

This section details some pre/post deployment steps for setting up specific apps

## Longhorn

Longhorn is a Cloud Native application for presistent block storage.  See [Longhorn docs](https://longhorn.io/docs/latest/).

To deploy Longhorn we utilise the longhorn helm chart. See [Chart Repo](https://github.com/longhorn/longhorn/tree/master/chart).

### Pre-deployment steps

#### 1. **(Optional)** Label nodes to run longhorn on

Make sure you have labelled your nodes so that longhorn can use them as storage nodes. 

If you're also managing `capi`, these are set for you - so you don't need to do anything.  

You want to label your worker nodes, the default label is `longhorn.store.nodeselect/longhorn-storage-node: "true`  

You can change this in the cluster-specific values like so:	

```yaml
longhorn:	
  longhornManager:	
    nodeSelector: 	
      # change this to whatever label you want	
      longhorn.store.nodeselect/longhorn-storage-node: true	
```	

> [!WARNING]
> If you are **NOT** using `capi` - make sure to set these labels accordingly for your cluster
 	

If you want to change the node labels that capi uses - you can do so like this: 

```yaml	
openstack-cluster:	
  nodeGroupDefaults:	
    nodeLabels:	
      # change this to whatever label you have set longhorn to use	
      longhorn.store.nodeselect/longhorn-storage-node: true
```	

#### 2. **(Optional)** Add TLS secret 	

Longhorn is configured to use TLS by default, by default it uses a self-signed certificate.

> [!CAUTION]
> For Production Systems, use a production certificate.
> Do **NOT** use a self-signed certificate.

You can create the TLS secret like so:

```bash
kubectl create secret tls longhorn-tls-keypair --key /path/to/privateKey.key --cert /path/to/certificate.crt -n longhorn-system
```

and set longhorn to use it in cluster-specific values file like so:

```yaml
longhorn:
  ingress:
    tlsSecret: longhorn-secret
```


### Post-deployement steps

Longhorn is already setup to be the default storageclass - if you're using CAPI you will need to drop csi-cinder storage class as being the default - you can do this by running

```bash
kubectl patch storageclass csi-cinder -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
```

### Common Problems 

#### 1. Longhorn web UI is giving a 500 and ArgoCD is stuck processing

Doing `kubectl get ds -n longhorn-system` shows a deployment with 0/0 instances

**Solution**:  You may be missing annotations on your node, refer to pre-deployment step 1

## Galaxy

Galaxy is a web-based platform for data analytics. 
See [Galaxy Docs](https://docs.galaxyproject.org/en/master/) 

To deploy galaxy we use the [Galaxy Chart Repo](https://github.com/galaxyproject/galaxy-helm)

### Prerequisites

Galaxy uses `longhorn` as default storage so make sure that it is available on the cluster

### Pre-deployment steps

#### 1. Create Secret for IAM Credentials

Create a secret for IAM credentials you can do so by creating a file in `/tmp/iam-secret.yaml` and adding this config:

```yaml
apiVersion: v1
data:
  client-id: "" # put client id here - remember to encode it in base64
  client-secret: "" # put client secret here - remember to encode it in base64
  cookie-secret: "" # any 32 digit alphanumeric
kind: Secret
metadata:
  name: iris-iam-credentials
  namespace: galaxy # make sure this matches namespace galaxy will be installed in 
type: Opaque
```	

you can create a random cookie secret by running
```bash
openssl rand -base64 32 | head -c 32 | base64
```

Then just apply the file 
```bash
kubectl apply -f /tmp/iam-secret.yaml 
```
