# (Deprecated) Deploying a new environment

> [!CAUTION]
> Its not recommended to deploy new environments to this repo, these docs are for information only
> To limit complexity, this repo will only manage `staging/management`, `staging/worker`, `prod/management` and `prod/worker` clusters and no others


> [!NOTE]
> The following documentation outlines how to deploy a **new** ArgoCD envrionment onto a `management` cluster.
> See [Deploying a Child Cluster](child-clusters.md) if you are deploying a cluster using an existing environment.


## Prerequisites: 

1. Create an application credential for your new cluster on your project
2. Ensure enough quota for the cluster (RAM, CPU, instances etc)
3. Provision a floating ip on your project for kubernetes API Server access
4. **(Optional)** Provision a second floating IP for nginx ingress controller
5. Create a self-managed cluster called `*-management-cluster` - replace `*` with the environment - either `prod` `dev` or `staging` 
   - see https://stfc.atlassian.net/wiki/spaces/CLOUDKB/pages/211878034/Cluster+API+Setup. 
   - Ensure the name matches `*-management-cluster` (with * as either `prod`, `dev` or `staging`) as CAPI cannot rename a cluster.


| :exclamation:  Make sure you already have a Kubernetes cluster deployed before proceeding with rest of the documentation   |
|----------------------------------------------------------------------------------------------------------------------|


## Motivation
You may want to make your own environment so you can test gitOps config or charts idependently of running clusters on test/feature branches

We don't want too many environments on `main` - especially those that aren't being used so there's less clutter

## Steps
To deploy another environment - follow these steps: 

1. Create a new branch for your work

2. Create a new folder `charts/<your-environment>`

3. Copy the charts from another environment - from either `prod`, `dev`, or `staging`. 

4. Create a new folder `clusters/<your-environment>`

5. Copy `management` subfolder from another environment into your newly created folder in `clusters`. 
You can optionally copy or create any other cluster subfolders you want to be in this environment here as well

6. Edit `apps.yaml`: 
See [Deploying apps](./deploying-apps.md) steps 2-3

- Any entries that begin with `path` should use charts from the new environment
- Any entries that begin with `valuesFiles` should use paths from the new environment
- remember to change `spec.template.metadata.name` so the prefix matches your environment name 
  
- **(Optional)** Any entries with `targetRevision` or `revision` should point to your new branch if you are using this branch for testing or as a feature branch and not intending on keeping it long-term

7. Modify the `infra-values.yaml` and any other cluster-specific values files as required 
- see [infra-setup](infra-setup.md) - "Pre-deployment" Steps

8. Modify/add any cluster-specific values for any apps you want to manage.
- see the upstream docs on what/how to change
- environment-specific values go in `clusters/<your-environment>/_shared`

9.  Modify infra secret files `.sops.yaml`, `api-sever-fip.yaml`, and `app-creds.yaml` under `clusters/<your-environment>/secrets/infra` 
See ([Deploying a child cluster on an existing environment](child-clusters.md) steps 6-8). 
Repeat for all other clusters you want to add

10.  Modify apps secret files including `.sops.yaml` under `clusters/<your-environment>/secrets/apps`
See ([Deploying a child cluster on an existing environment](child-clusters.md) steps 9-12). 

Repeat the steps 4-10 for all other clusters you want to add

> [!CAUTION]
> Make sure these files has been **encrypted** using SOPS in the steps above before committing and pushing changes to your branch.

11.  **(Optional)** If this is not a temporary environment - and you want to keep it around long term in `main` make a PR for it and get it merged

12.  Deploy age private key secret to management cluster

**New to generating age keys and generating secrets?** See [secrets](secrets.md) for more information

```bash
cd scripts; ./deploy-helm-secret.sh <path-to-age-private-key>
``` 

13. Run deploy.sh on your self-managed cluster `*-management-cluster` like so:

```bash
cd scripts; ./deploy.sh management <your-environment>  
```

when deploying argo onto child clusters - replace `management` with the cluster's folder name 

e.g. to deploy worker cluster apps - run 
```bash
cd scripts; ./deploy.sh worker <your-environment>  
```
14.  Wait for argocd to deploy and all apps should spring to life in the UI and spin up any other clusters you've defined

15.  Repeat step 12-14 for each extra cluster that you have running - to deploy argocd onto the cluster.

You can get the kubeconfig to access these clusters once all the apps on the `management` cluster is up and running 
`clusterctl get kubeconfig $CLUSTER_NAME -n clusters > $CLUSTER_NAME.kubeconfig`