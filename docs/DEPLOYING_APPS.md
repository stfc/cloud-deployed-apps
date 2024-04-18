# Deploying Apps

This document outlines how to deploy infrastructure, as well as pre-deployment and post-deployment steps to setup "app" charts on a cluster.

## Managing Apps for a cluster

To add/edit infrastructure charts for a cluster, you'll want to edit the file `app-values.yaml` 

make sure that global configuration is set at the top of the file

```
global:
  # name of the cluster 
  # MUST MATCH THE DIRECTORY NAME
  clusterName: test-cluster

  spec:
    source:
      targetRevision: <your branch>

      # change this if you're using a fork
      repoURL: https://github.com/stfc/cloud-deployed-apps.git 

      # namespace where the argocd applications will be installed to 
      namespace: argocd

```

then you can add apps like so:

```
apps:
  # name of argocd application
  - name: app-1

    # when true, will disable auto-sync and auto-heal on the argocd app
    disableAutomated: false

    # name of the chart to install - corresponds with chart name in charts/apps/
    chartName: app1

    # namespace where the chart contents will be installed to
    namespace: app-ns

    # a list of filepaths to cluster-specific values for a given chart
    # overrides defaults set for that chart
    additionalValueFiles: 
      - clusters/test-cluster/overrides/apps/app1-overrides.yaml

    # (optional) can define the git SHA to sync against specific to the app
    # This overrides global.spec.source.targetRevision
    # targetRevision: <other-branch>
```

**NOTE: `app-values.yaml` is required even if no apps are being deployed - this is because argocd will always be self-managed as an app for the cluster**

## Configuring ArgoCD

To configure argocd there is a special `argocd-values.yaml` for each cluster. 
This is used to setup self-managed argocd. 

One of the main reasons you'll want to configure argocd is to change the domain name. You can do this like so:

```
argo-cd:
  global: 
    # default is argocd.example.com
    domain: "argocd.example.io" 
```

# Chart Specific Documentation

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
