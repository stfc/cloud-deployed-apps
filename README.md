# Kubernetes Deployed Apps using ArgoCD for the STFC Cloud 

A collection of helm charts and configurations that are being used by the STFC Cloud for various clusters. 

This repo acts as the "central repository" of all configuration information for our K8s clusters. 

We use ArgoCD to manage our clusters and each cluster we manage has its own ArgoCD instance which syncs to this repo.

# Repository Structure

This repository contains the following directories:

- `charts` - This directory holds helm charts for each of our apps that we want to manage. Charts are organised into `apps` and `infra`. Each Chart contains "default" configuration files for each.

- `appofapps` - This directory holds `appofapps.yaml` which creates an ArgoCD Application resource that installs the apps on our clusters. 

- `clusters` - This directory contains cluster-specific values and patch files. These values override the "default" values allowing us to have slightly different configurations on our clusters - such as having different production and staging clusters 

- `scripts` - This directory contains various "helper" scripts that we might use for cluster management



# Usage

We can use this repository structure to manage multiple clusters and easily turn on and off apps we want to have running on our cluster. 

See below on how to do certain common workflow patterns:

## deploying appofapps to a new cluster

To make a new cluster definition in this repo, you'll want to:

### 1. Create a new K8s cluster 

You can create a CAPI cluster of STFC Cloud following this link https://stfc.atlassian.net/wiki/spaces/CLOUDKB/pages/211878034/Cluster+API+Setup. 

This repo can be used for non-CAPI clusters
  - `apps` provided in `charts/apps` should work on any K8s cluster. 

  - `infra` charts are more specific. `infra/capi` can be used for getting argocd to self-manage or make child clusters 
 

### 2. Make a fork of this repo 

Then Clone the forked repo onto your VM/local machine

Make sure you can access the cluster you've created with kubectl commands

**Your first commit should be to change the global `repoURL` in `charts/base/values.yaml`**

```
# charts/base/values.yaml
global:
...
spec:
    ...
    repoURL: <change this to your github fork link>
```

You will also need to change `repoURL` in `appofapps/appofapps.yaml` 

### 3. Create a directory `clusters/<name-of-you-cluster>` 

Add boilderplate files to enable patching through kubernetes kustomize.
This allows cluster-specific configuration to override default config set in `charts/`

create `clusters/<name-of-your-cluster>/kustomization.yaml` file 
```
# kustomization.yaml

apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- ../../appofapps/

patches:
- target:
    group: argoproj.io
    version: v1alpha1
    kind: Application
    name: appofapps
  path: cluster-patch.yaml

```

create `clusters/<name-of-your-cluster>/cluster-patch.yaml` file
```
# cluster-patch.yaml

- op: add
  path: /spec/source/helm/valueFiles/-
  value: ../clusters/<name-of-your-cluster>/values.yaml
```

### 4. create `clusters/<name-of-your-cluster>/values.yaml` file 

Here your can specify the apps you want. 

See `clusters/staging-management-cluster/values.yaml` for a good example


### 5. create overrides folder `clusters/<name-of-your-cluster>/overrides`

Place your overriding values files in here for each app. 

NOTE: most of our Helm charts are just boilerplate, and make use of "dependency" charts to install apps. So when overriding values, remember you're changing dependecy charts. 

e.g. to override `openstack-cluster` Helm chart values for the `infra` app, (which uses it as a dependency) you'll want to do:

```
openstack-cluster:
    # place your values here
```

The reason we do this is to bundle together multiple charts into a single app. Useful for deploying a stack of tools that accomplish one purpose - such as our logging stack.

### 6. Deploy and test your new cluster
run the following to deploy your cluster
```
cd scripts
./deploy <name-of-your-cluster>
```

Deploying will create a bootstrap argocd service which will then install and manage your configured apps. 

If you want to expose argocd via a loadbalancer you can do so by running:

```
helm upgrade argocd argo/argo-cd \
  --reuse-values \
  --namespace argocd \
  --set server.service.type=LoadBalancer
  --set server.service.loadBalancerIP=<argocd-float-ip>
  --wait
```

NOTE: this won't work if you've set `argocd` as one of the apps the cluster is managing - in that case it's defaulted to use ingress. You can change this to use a loadbalancer with cluster-specific config instead


### 7. Make a PR and get your changes reviewed

Your last commit should be to change back the `repoURL` to this repo link: https://github.com/stfc/cloud-deployed-apps.git and change the `repoURL` in `appofapps.yaml` 


### 8. Once the changes are merged, you'll need to manually patch the cluster to use this repo

run this patch on your cluster
`kubectl patch app -n argocd appofapps --type replace -p '{"spec":{"source":{"repoURL":"https//:github.com/stfc/cloud-deployed-apps.git"}}}`

## Adding a new application/infrastucture to manage

To add a new application, you'll need to

### 1. Create a directory under `charts/` for your app. 

if its an app place in `charts/apps`

if its infrastructure related, place in `charts/infra`

We treat every application as a helm chart so that we can use argocd to manage it easily

Write Chart.yaml boilerplate
```
# Chart.yaml

apiVersion: v2
name: <name-of-your-app>-apps
version: 1.0.0
dependencies:
  # put your chart dependecies here - usually the thing you want to install
  - name: <name of chart>
    version: <chart version>
    repository: <url to install the chart from>
```

you can find the repo url by doing a `helm repo list` if you've got it installed, similarly `helm search repo <repo-name>` to get chart names and latest version available

### 3. (Optional) Create `charts/<path-to-your-app>/templates>` file and add bespoke helm templates (if needed)

If you require bespoke resource definitions, you can write them in `templates` and use helm templating to allow them to be configured

### 4. Write default values files 

NOTE: Can be multiple files. 
Best practice is to place it alongside the `Chart.yaml` file

### 5. Edit the file `charts/base/values.yaml` 

if you're adding an `app` - add your app's default filepaths like so:

```
# charts/base/values.yaml

appValueFiles:
  ... 
  # append to this config with your app
  <app-name>:
    - charts/<apps-to-your-app>/<your-values-file>.yaml
    - charts/<path-to-your-app>/<your-values-file2>.yaml
    ...
```

if you're adding `infra`, instead edit `infraValueFiles` in the same way

## Making updates to existing applications

To make an update to an existing applications, you can edit the templates or values files in `charts/<path-to-app-name>/` and make a PR for the changes. 

Once merged, ArgoCD running on the cluster should pick up the changes automatically (if `targetRevision` is kept as `HEAD`). 

NOTE: cluster overrides may need tweaking or this may break them/ not take affect if you're making large changes 

Its a good idea to test changes on a development branch first with a dev cluster pointing to it to test changes before making a PR to main - see development workflow

## Making updates to existing clusters

To make an update to an existing clusters, you can edit the files in `clusters/<cluster-name>/overrides/` and make a PR for the changes. 

Once merged, ArgoCD running on the cluster should pick up the changes automatically (if `targetRevision` is kept as `HEAD`)


### Updating (Helm Chart) versions

To make updates to versions you can edit the `Chart.yaml` for the specific version you want to change and make a PR. 

If you suspect it's a breaking change or something needs tweaking, follow the development workflow below. 

Minor version changes should be fine to make a PR for without needing to make a fork, we can test on our staging clusters


# Best Practices

## Development workflow

If you're making large changes to this repo, it's recommended you follow the following steps

### 1. Make a fork of this repo
   - your first commit should be to change the global `repoURL` in `charts/base/values.yaml`
  ```
  # charts/base/values.yaml
  global:
    ...
    spec:
      ...
      repoURL: <change this to your github fork link>
  ```
  - also change the `repoURL` in `appofapps.yaml` 

### 2. Make a new dev cluster
  - you can create a new cluster definition in `clusters` or re-use an existing one 
  - reusing a staging cluster definition is recommended as the override values will be preserved - tweak these if it doesn't work
  - use it to test changes. 
  
### 3. Once happy, delete your dev cluster

### 4. Change back the `repoURL` 
```
# charts/base/values.yaml
global:
  ...
  spec:
    ...
    repoURL: https//:github.com/stfc/cloud-deployed-apps.git
```
- also change the `repoURL` back in `appofapps.yaml` 

### 5. Make a PR and get it reviewed/merged
   - since our dev clusters will be following `HEAD` your changes will automatically go into staging (as long as you set it to being used)


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

If you're deploying an app for the first time to a cluster, you may want to push a commit with `disableAutomated` on it to begin with. If there's an error, this allows you to diagnose more easily without argo constantly performing syncs underneath you


# Infra-specific Documentation

## Capi

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

