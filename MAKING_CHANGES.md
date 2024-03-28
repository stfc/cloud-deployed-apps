# Making Changes To This Repo




# Making Changes

There are 4 main reasons you will want to make changes to this repository

In all cases, you will want to follow this developemnt workflow for testing changes (see below)


## 1. Adding a Cluster

1. Add a directory in `clusters/<name-of-your-cluster>`

2. Create `clusters/<name-of-your-cluster>/values.yaml` file and define apps and infra you'd like argocd to manage

see `clusters/test-cluster/values.yaml` for a good example


## 2. Making Changes to Existing Apps/Clusters

Look in `charts/base/values.yaml` in `valuesFiles` to see locations where default values files are defined for the app

For cluster specific values - you'll have to look in `clusters/<cluster-name>/values.yaml` for an app declaration. Cluster-specific values files for an app are listed under `additionalValuesFiles` for the app definition (under `apps`) if set.

**NOTE: make sure to update the Chart version if you make any changes to custom `templates` files**


## 3. Making Version Changes to Apps

To make updates to versions you can edit the `Chart.yaml` for the specific version you want to change and make a PR. 

If you suspect it's a breaking change or something needs tweaking, follow the development workflow below. 

Minor version changes should be fine to make a PR for without needing to make a fork, we can test on our staging clusters


## 4. Adding a New Chart

To add a new chart follow these steps



# Testing Changes

Whether you are contributing or reviewing changes, its a good idea to create a cluster to test changes before pushing to `main`.

Here are the steps you would follow to test changes

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

**make a commit that:** 
   - changes the global `repoURL` in `charts/base/values.yaml`

```
# charts/base/values.yaml

global:
  ...
  spec:
      ...
      repoURL: <change this to your github fork link>
```
This will make it so that when you deploy a cluster using this fork, it will use your latest changes on your fork rather than `stfc` repo.


## 2b. Make a branch off of this repo

If you decide to make a branch follow these steps:

create a branch for development off of `main`

**make a commit that:** 
  - changes the `targetRevision` in `charts/base/values.yaml`

 
```
# clusters/<name-of-cluster>/values.yaml

global:
  ...
  spec:
    ...
    targetRevision: <change this to your github branch or commit SHA>

```

This will make it so that when you deploy a cluster using this branch, it will use your latest changes on your branch rather than `main`.


## 3. Make your changes
see Making Changes section below

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
Your last commit should be to change back the `repoURL` to this repo link: `https://github.com/stfc/cloud-deployed-apps.git`


### 6b. If working on a branch
Your last commit should be to change back the `gitRevision` back to `main`

### 7. Mark the PR ready for review and get it merged

Merging this PR should be fairly quick now as the major changes have been fixed 
