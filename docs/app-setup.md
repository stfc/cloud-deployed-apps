# App Setup Steps

This section details some pre/post deployment steps for setting up specific apps

# Longhorn

Longhorn is a Cloud Native application for presistent block storage.  See [Longhorn docs](https://longhorn.io/docs/latest/).

To deploy Longhorn we utilise the longhorn helm chart. See [Chart Repo](https://github.com/longhorn/longhorn/tree/master/chart).

# Pre-deployment steps

# 1. (Optional) Label nodes to run longhorn on

Make sure you have labelled your nodes so that longhorn can use them as storage nodes. 

If you're also managing `capi`, these are set for you - so you don't need to do anything.  

You want to label your worker nodes, the default label is `longhorn.store.nodeselect/longhorn-storage-node: "true`  

You can change this in the cluster-specific values like so:	

```	
longhorn:	
  longhornManager:	
    nodeSelector: 	
      # change this to whatever label you want	
      longhorn.store.nodeselect/longhorn-storage-node: true	
```	

**NOTE:** If you're NOT using `capi` - make sure you set these labels accordingly for your cluster. 	

If you want to change the node labels that capi uses - you can do so like this: 

```	
openstack-cluster:	
  nodeGroupDefaults:	
    nodeLabels:	
      # change this to whatever label you have set longhorn to use	
      longhorn.store.nodeselect/longhorn-storage-node: true
```	

# 2. (Optional) Add tls secret 	


Longhorn is configured to use TLS by default, by default it uses a self-signed certificate which is not secure - recommended to get a proper certificate for production systems.	Longhorn is configured to use TLS by default, by default it uses a self-signed certificate which is not secure - recommended to get a proper certificate for production systems.


Footer


# 2. (Optional) Add tls secret 

Longhorn is configured to use TLS by default, by default it uses a self-signed certificate which is not secure - recommended to get a proper certificate for production systems.

you can create the tls secret like so:

```
kubectl create secret tls longhorn-tls-keypair --key /path/to/privateKey.key --cert /path/to/certificate.crt -n longhorn-system
```

and set longhorn to use it in cluster-specific values file like so:
```
longhorn:
  ingress:
    tlsSecret: longhorn-secret
```


# Post-deployement steps

Longhorn is already setup to be the default storageclass - if you're using CAPI you will need to drop csi-cinder storage class as being the default - you can do this by running

```
kubectl patch storageclass csi-cinder -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
```

# Common Problems 

## 1. Longhorn web UI is giving a 500 and ArgoCD is stuck processing

Doing `kubectl get ds -n longhorn-system` shows a deployment with 0/0 instances

**Solution**:  You may be missing annotations on your node, refer to pre-deployment step 1
