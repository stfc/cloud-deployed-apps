# Making Changes To This Repo

There are two main reasons you will want to make changes to this repository

1. Adding a new cluster to be managed
2. Adding/Editing existing charts that clusters can use

In both cases, you will want to follow this workflow


## 1. Create a new K8s cluster for testing changes 

You can create a CAPI cluster of STFC Cloud following this link https://stfc.atlassian.net/wiki/spaces/CLOUDKB/pages/211878034/Cluster+API+Setup. 

**NOTE:** To avoid issues with capi and cluster-names - please name your testing cluster the same name as the cluster you want to edit/add 
   - use `test-cluster` if you are adding/editing a chart
   

**NOTE:** This repo can be used for non-CAPI clusters
  - `apps` provided in `charts/apps` should work on any K8s cluster. 

  - `infra` charts are more specific. 
    - For example - `infra/capi` chart requires a CAPI cluster in order to work


Once you've created a cluster, make sure your development environment can access your cluster with kubectl commands for later steps.

The next step is your choice - either a fork or a branch

## 2a. Making a fork of this repo 

If you decide to make a fork follow these steps:

Clone the forked repo onto your VM/local machine

**Your first commit should be to:** 
   - change the global `repoURL` in `charts/base/values.yaml` and

```
# charts/base/values.yaml

global:
...
spec:
    ...
    repoURL: <change this to your github fork link>
```


## 2b. Make a branch off of this repo

If you decide to make a branch follow these steps:

create a branch for development off of main (`HEAD`)


## 3. Make your changes


### 1. Adding a Cluster

1. Add a directory in `clusters/<name-of-your-cluster>`

2. Add boilerplate files to enable patching through kubernetes kustomize.
   
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


create `clusters/<name-of-your-cluster>/values.yaml` file and define apps and infra you'd like argocd to manage

see `clusters/test-cluster/values.yaml` for a good example


### 2. Making Changes to Existing Apps/Clusters

Look in `charts/base/values.yaml` in `valuesFiles` to see locations where default values files are defined for the app

For cluster specific values - you'll have to look in `clusters/<cluster-name>/values.yaml` for an app declaration. Cluster-specific values files for an app are listed under `additionalValuesFiles` for the app definition (under `apps`) if set.

**NOTE: make sure to update the Chart version if you make any changes to custom `templates` files**


### 3. Making Version Changes to Apps

To make updates to versions you can edit the `Chart.yaml` for the specific version you want to change and make a PR. 

If you suspect it's a breaking change or something needs tweaking, follow the development workflow below. 

Minor version changes should be fine to make a PR for without needing to make a fork, we can test on our staging clusters


### 4. Adding a New Chart

To add a new chart follow these steps

#### 1. Create a directory under `charts/` for your app
- if its an app place in `charts/apps`
  - an app is system agnostic and should work on any K8s cluster

- if its infrastructure related, place in `charts/infra`
  - infrastructure charts can only be used on certain K8s clusters

Write Chart.yaml boilerplate in `charts/../<name-of-chart>`
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

**NOTE: ** If you require bespoke resource definitions, you can write them in `templates` and use helm templating to allow them to be configured. Create `charts/<path-to-your-app>/templates>` file and add bespoke helm templates (if needed)

#### 2. Create default values files

These are usually placed next to `Chart.values`

**NOTE: remember that charts are added as dependencies** so you'll need to encase any values pertaining to a chart in its name - i.e. 

```
# chart dependency name
openstack-cluster
    # values related to openstack-cluster
    # found in https://stackhpc.github.io/capi-helm-charts
```

#### 3. Add default filepaths to `charts/base/values.yaml`

Add your chart's default filepaths like so:

```
# charts/base/values.yaml

valueFiles:
  ... 
  # append to this config with your app
  <app-name>:
    - charts/<apps-to-your-app>/<your-values-file>.yaml
    - charts/<path-to-your-app>/<your-values-file2>.yaml
    ...
```

Then you can toggle on/off this app in existing clusters - best to test with the `test-cluster` archetype


### 5b. If working from a branch

Before you deploy your changes, commit them and get the latest git SHA hash.

Make another commit to modify `targetRevision` for the cluster you want to deploy to

```
# clusters/<name-of-cluster>/values.yaml

global:
  spec:
    source:
      targetRevision: <git SHA here>

```

This will make it so that when you deploy your cluster, it will use your latest changes rather than `main` `HEAD`.

**NOTE**: further commits will require an extra commit to update the git SHA so argocd pickes up the latest changes you make

### 4. Deploy your changes to your test cluster

run the following to deploy your cluster
```
# should match a sub-directory under clusters/
cd scripts && ./deploy <name-of-your-cluster> 
```

Deploying will create a bootstrap argocd service which will then install and manage your configured apps. 

**NOTE: Argocd is not self-managed by default**.

- if you want to leave it without self-managing you can expose argocd via a loadbalancer you can do so by running:

```
helm upgrade argocd argo/argo-cd \
  --reuse-values \
  --namespace argocd \
  --set server.service.type=LoadBalancer
  --set server.service.loadBalancerIP=<argocd-float-ip>
  --wait
```

ArgoCD uses ingress by default if set to self-manage - just add it as an app for your cluster. It's recommended to have argocd self-manage and use Ingress as it provides TLS termination and hence more secure

### 5. Once happy, make a Draft PR

Get your changes reviewed at this time - make sure that any large issues are addressed now 

This is especially important if you're adding new features

For small changes like version changes - you can skip draft PR stage

It's a good idea to keep the cluster around until the PR has been reviewed and any major changes requested has been tested 

### 6. Delete your testing cluster 

### 6a. If working on a fork
Your last commit should be to change back the `repoURL` to this repo link: https://github.com/stfc/cloud-deployed-apps.git


### 6b. If working on a branch
Your last commit should be to change back the `gitRevision` back to `HEAD`

### 7. Mark the PR ready for review and get it merged

Merging this PR should be fairly quick now as the major changes have been fixed 




