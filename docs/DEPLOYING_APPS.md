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

## 1. Label nodes to run longhorn on 

Make sure you have labelled your nodes so that longhorn can use them as storage nodes. You want to label your worker nodes, the default label is `longhorn.demo.io/longhorn-storage-node=true` but you can change this in the cluster-specific values like so:

```
longhorn:
  longhornManager:
    nodeSelector: 
      # change this to whatever label you want
      longhorn.demo.io/longhorn-storage-node: "true"
```

**NOTE:** If you're using `capi` or any other `infra` that you're also managing with argocd - make sure you set these labels accordingly for your cluster. 

For `capi` you can set node labels like so:

```
openstack-cluster:
  nodeGroupDefaults:
    nodeLabels:
      # change this to whatever label you have set longhorn to use
      longhorn.demo.io/longhorn-storage-node: true
```

# 2. Add tls secret 

Longhorn is configured to use TLS by default, therefore a tls secret is required. 

You can create a self-signed cert for testing like so:

```
openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -keyout privateKey.key -out certificate.crt
```

and create the secret like so:

```
kubectl create secret tls tls-keypair --key /path/to/privateKey.key --cert /path/to/certificate.crt -n longhorn-system
```

# Post-deployement steps

Longhorn is already setup to be the default storageclass - if you're using CAPI you will need to drop csi-cinder storage class as being the default - you can do this by running

```
kubectl patch storageclass csi-cinder -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
```