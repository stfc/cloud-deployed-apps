# Deploying ArgoCD to a Cluster 

This section outlines how to set up a cluster to run ArgoCD.

> [!NOTE]
> This documentation assumes that you already have a kubernetes cluster. To create a cluster, see [Cluster API Setup](https://stfc.atlassian.net/wiki/spaces/CLOUDKB/pages/211878034/Cluster+API+Setup)

> [!TIP]
> Make sure you have a floating IP allocated if you are planning to use ingress.


**Starting From Scratch:** Start from [Deploying a new cluster](#deploying-a-new-cluster)

**Modify an exisitng cluster:** Start from [Modifying an existing cluster](#3---modifying-an-existing-cluster)


## Deploying a New Cluster

### 1 - Create Development Branch
This can be a branch from `main` on this repo, or create a fork of this repo and work on the `main` branch from there.

Create a branch for development off of `main` for making changes

### 2 - Adding a new cluster to manage

On the management VM for the cluster, clone this repo/fork and/or checkout to your development branch.


If you're adding a new cluster to manage, you will need to create a new entry in the `clusters` directory. You'll have to create the following files/directories:

```
clusters/
    -> <CLUSTER-NAME>/
      - app-values.yaml
      - argocd-values.yaml
      - infra-values.yaml
      -> overrides/
        - cluster-self-manage.yaml
```

### 3 - Modifying an existing cluster

If you want to modify an existing cluster, there should already be an existing directory in `clusters` with the same name as the cluster you want to modify. Clone this repository and create a new branch for development, or create a fork of the repo.


### 4 - (Optional) Configure cluster-specific values

If not already done, you can specify which apps you want to `app-values.yaml`
- If starting an ArgoCD cluster from scratch, you will need to configure the `cluster-self-manage.yaml` file. See `clusters/staging-management-cluster/overrides/infra/deployment.yaml` for reference.

- see [Deploying Apps](./DEPLOYING_APPS.md) for how to configure apps and argocd

You can also specify which infra you want to for your cluster using `infra-values.yaml` 
  
- see [Deploying Infra](./DEPLOYING_INFRA.md) for how to configure infra changes

You can modify argocd values in `argocd-values.yaml`

- see [Deploying Apps](./DEPLOYING_APPS.md) section on configuring argocd

Make commits and push changes to your branch/fork.

### 5 - Change cluster to point to your branch/fork

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

> [!NOTE]
> Ensure that `app-values.yaml` cluster-specific global settings have been modified to point to your branch or fork **even if you are not deploying any apps.**

- This is because argocd uses global config set in `app-values.yaml` to configure and manage itself

Then push your changes 

### 6 - Run any pre-deployment steps

For each app/infra you've enabled, see if there are any pre-deployment steps you need to run before deploying argocd

### 7 - Deploy argocd onto the cluster

ssh into your management VM or have a place where you can run kubectl commands on the cluster you want to deploy argocd to.

Clone the repo/fork and checkout the branch with your cluster changes

run `cd scripts && ./deploy <name-of-your-cluster>` to deploy argocd to your cluster

### 8 - Run any post-deployment steps

For each app/infra you've enabled, see if there are any post-deployment steps you need to run before deploying argocd

### 9 - Make a Draft PR

Make a PR to add your new cluster config so it can be tracked in `main`. Get someone to review your changes - they should spin up the cluster themselves using your branch

Once everyone is happy make one final commit.
> [!WARNING]
> This will likely make your cluster go out-of-sync

#### If using a branch

**Make a commit that:** changes the `global.spec.source.targetRevision` in `clusters/<your-cluster-name>/infra-values.yaml` back to `main`

#### If using a fork

**Make a commit that:** changes the `global.spec.source.repoURL` in `clusters/<your-cluster-name>/infra-values.yaml` back to `https://github.com/stfc/cloud-deployed-apps.git`


Once the PR is merged, to keep your cluster tracking properly. Redo steps 6-8 using `https://github.com/stfc/cloud-deployed-apps.git` repo checking out `main`