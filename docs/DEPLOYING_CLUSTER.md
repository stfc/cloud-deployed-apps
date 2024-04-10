# Deploying ArgoCD to a Cluster 

In this section we will outline how to setup a cluster to use argocd synced to this repo

## Requirements

you must have:
  1. A kubernetes cluster. Follow our guide for setting up a CAPI Cluster https://stfc.atlassian.net/wiki/spaces/CLOUDKB/pages/211878034/Cluster+API+Setup


## Deploying existing cluster with no changes

If you're deploying a cluster that has already been pre-configured, and you're not making any changes - you can just clone this repo and **follow steps 6-8 only** - shown below


## Deploying a new cluster, or modifying an existing cluster

## 1a. Make a branch for your changes

Create a branch for development off of `main` for making changes


## 1b. (Alternatively) making a fork for your changes 

You can alternatively decide to make a fork


## 2. Adding a new cluster to manage

Clone your this repo/fork and/or checkout your new branch 

If you're adding a new cluster to manage, you will need to create a new entry in the `clusters` directory. You'll have to create the following files/directories:

```
clusters/<your-cluster-name>/overrides/
clusters/<your-cluster-name>/app-values.yaml
clusters/<your-cluster-name>/argocd-values.yaml
clusters/<your-cluster-name>/infra-values.yaml
```

## 3. Modifying an existing cluster

If you want to modify an existing cluster, there should already be an existing directory in `clusters` with the same name as the cluster you want to modify


## 4. (Optional) Configure cluster-specific values

If not already done, you can specify which apps you want to `app-values.yaml`

- see [Deploying Apps](./DEPLOYING_APPS.md) for how to configure apps and argocd

You can also specify which infra you want to for your cluster using `infra-values.yaml` 
  
- see [Deploying Infra](./DEPLOYING_INFRA.md) for how to configure infra changes

You can modify argocd values in `argocd-values.yaml`

- see [Deploying Apps](./DEPLOYING_APPS.md) section on configuring argocd

Make a commit and push changes

## 5. Change cluster to point to your branch/fork

**If using a branch:**

**make a commit that:** changes `global.spec.source.targetRevision` in `clusters/<your-cluster-name>/infra-values.yaml`
 
```
# clusters/<name-of-cluster>/infra-values.yaml

global:
  ...
  spec:
    ...
    source:
      targetRevision: <change this to your github branch or commit SHA>
```

**If using a fork:**

**make a commit that:** changes the `global.spec.source.repoURL` in `clusters/<your-cluster-name>/infra-values.yaml`

```
# clusters/<name-of-cluster>/infra-values.yaml

global:
  ...
  spec:
    ...
    source:
      repoURL: <change this to your github fork link>

      # change this if you are using another branch on your fork
      targetRevision: main 
```

**NOTE: Ensure that `app-values.yaml` cluster-specific global settings have been modified to point to your branch or fork EVEN IF YOU ARE NOT DEPLOYING ANY APPS**
- This is because argocd uses global config set in `app-values.yaml` to configure and manage itself

Then push your changes 

## 6. Run any pre-deployment steps

For each app/infra you've enabled, see if there are any pre-deployment steps you need to run before deploying argocd

## 7. Deploy argocd onto the cluster

ssh into your management VM or have a place where you can run kubectl commands on the cluster you want to deploy argocd to.

Clone the repo/fork and checkout the branch with your cluster changes

run `cd scripts && ./deploy <name-of-your-cluster>` to deploy argocd to your cluster

## 8. Run any post-deployment steps

For each app/infra you've enabled, see if there are any post-deployment steps you need to run before deploying argocd

## 9. Make a Draft PR

Make a PR to add your new cluster config so it can be tracked in `main`. Get someone to review your changes - they should spin up the cluster themselves using your branch

Once everyone is happy make one final commit (**THIS WILL LIKELY MAKE YOUR CLUSTER GO OUT-OF-SYNC**):

**If using a branch:**

**make a commit that:** changes the `global.spec.source.targetRevision` in `clusters/<your-cluster-name>/infra-values.yaml` back to `main`

**If using a fork:**

**make a commit that:** changes the `global.spec.source.repoURL` in `clusters/<your-cluster-name>/infra-values.yaml` back to `https://github.com/stfc/cloud-deployed-apps.git`


Once the PR is merged, to keep your cluster tracking properly. Redo steps 6-8 using `https://github.com/stfc/cloud-deployed-apps.git` repo checking out `main`