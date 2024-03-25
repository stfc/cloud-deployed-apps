# Kubernetes Deployed Apps using ArgoCD for the STFC Cloud 

A collection of helm charts and configurations that are being used by the STFC Cloud for various clusters. 

This repo acts as the "central repository" of all configuration information for our K8s clusters. 

We use ArgoCD to manage our clusters and each cluster we manage has its own ArgoCD instance which syncs to this repo.

see [MAKING_CHANGES](./MAKING_CHANGES.md) on how to add clusters/charts to this repo


# Chart-Specific Documentation

## CAPI

"capi" is used to configure and manage the cluster itself and any child clusters.  

This app configures Cluster API. 

Cluster API is a tool for provisioning, and operating K8s clusters. We use this tool to run K8s on Openstack. 

We utilise StackHPCs CAPI Chart to do this - https://github.com/stackhpc/capi-helm-charts

### pre-deployment steps

As with all other apps, make sure you setup a cluster with valid credentials first. Following our guide https://stfc.atlassian.net/wiki/spaces/CLOUDKB/pages/211878034/Cluster+API+Setup

1. Make sure you have provisioned a floating ip for the cluster's ApiServer.

2. By default, this application will setup nginx-ingress and a floating ip will be required. Ensure you have another floating ip configured for this.
  
NOTE: you can turn off ingress by adding this config to a values.yaml file in `clusters/<cluster-name>/overrides` (or creating a new one):
```
openstack-cluster:
  addons:
    ingress:
      enabled: false
```

Make sure that the file you created/added to is referenced in `clusters/<cluster-name>/values.yaml` like so:

```
infra:
  - name: <cluster-name>
    ...
    appName: capi
    ...
    additionalValueFiles: 
      - clusters/<cluster-name>/overrides/<override-file1>.yaml
      - clusters/<cluster-name>/overrides/<override-file2>.yaml
```

### post-deployment

Once you deploy this application, you need to manually set the floating ip for the APIServer and ingress (if enabled)

create a file called `capi_patch.yaml`

```
spec:
  source:
    helm:
      parameters:
      - name: openstack-cluster.apiServer.floatingIP
        value: <APIServer floating ip here>
      - name: openstack-cluster.addons.ingress.nginx.release.values.controller.service.loadbalancerIP
        value: <ingress nginx floating here>
```

then you can run: 
`kubectl patch -n argocd app <infra-app-name> --patch-file capi_patch.yaml --type merge`



# Repository Structure

This repository contains the following directories:

- `charts` - This directory holds helm charts for each of our apps that we want to manage. Charts are organised into `apps` and `infra`. Each Chart contains "default" configuration files for each.

- `appofapps` - This directory holds `appofapps.yaml` which creates an ArgoCD Application resource that installs the apps on our clusters. 

- `clusters` - This directory contains cluster-specific values and patch files. These values override the "default" values allowing us to have slightly different configurations on our clusters - such as having different production and staging clusters 

- `scripts` - This directory contains various "helper" scripts that we might use for cluster management



## Using targetRevision

For this repo, we'll aim to keep a single branch `main` to be used by ArgoCD. 
All clusters will use the config from the latest commit `HEAD`

This has several advantages:
     - `HEAD` will contain all up-to-date information for all our clusters
     - small updates can be applied quickly to all applicable clusters

However, this makes our production clusters potentially unstable. 

To mitigate this - we can specify `targetRevision` on specific apps (or globally for a cluster).

`targetRevision` will allow ArgoCD to take a previous git commit hash, and use it to sync with for that cluster.

To set `targetRevision` for the whole cluster modify the file `clusters/<cluster-name>/values.yaml`: 

```
global:
  spec:
    source:
      targetRevision: <git commit SHA>
```

to set `targetRevision` for a specific app modify the file `clusters/<cluster-name>/values.yaml`:

```
apps:
  - name: <app-name>
    targetRevision: <git commit SHA>
    ...
```

## Disable automation

If you're deploying an app for the first time to a cluster, you may want to push a commit with `disableAutomated` on it to begin with. 

You can set `disableAutomated` for each app/infra you enable for your cluster. Modify the file `cluster/<cluster-name>/values.yaml`:

```
apps:
  - name: <app-name>
    disableAutomated: true
    ...
```

If there's an error, this allows you to diagnose more easily without argo constantly performing syncs underneath you
