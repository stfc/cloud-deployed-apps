# Deploying a child cluster on an existing environment

> [!NOTE]
> The following documentation outlines how to deploy child clusters in an **existing** environment.
> See [Deploying a new environment](clusters.md) if deploying a new ArgoCD environment

## Prerequisites: 
1. Create an application credential for the project the child cluster should be deployed in
2. Ensure the project has enough quota for the cluster (RAM, CPU, instances etc)
3. Provision a floating ip on your project for kubernetes API Server access
4. (Optional) Provision a second floating IP for nginx ingress controller

## Steps
To deploy a new child cluster on an existing environment follow these steps:

1. Create a branch off of main
2. Create a new folder under `clusters/<environment>/<cluster-name>`
3. Create a file in `clusters/<environment>/<cluster-name>/infra-values.yaml` 
4. Populate the `infra-values.yaml` file with cluster-specific values for the chart in `capi-infra` chart. 

It could look like this:

```yaml
stfc-cloud-openstack-cluster:
  openstack-cluster:

  # defining the number of control-plane nodes
    controlPlane:
      machineCount: 3

  # defining the number of worker nodes
    nodeGroups:
      - name: default-md-0
        machineCount: 2

  # worker node flavor
    nodeGroupDefaults:
      machineFlavor: l3.nano

  # addon config for the cluster 
  # here we define an nginx ingress controller service
    addons:
      ingress:
        enabled: true
        nginx:
          release:
            values:
              controller:
                service:
                  # create a floatip for ingress on your project and put it here
                  loadBalancerIP: "130.xxx.yyy.zzz" 
```

5. Create a new folder under `clusters/<environment>/<cluster-name>/secrets/infra`

6. Copy `.sops.yaml` from  `clusters/<environment>/management/secrets/infra/.sops.yaml` 
See [Secrets](secrets.md) for more information on Sops Secrets

> [!NOTE]
> If your public age key is not already in the copied `.sops.yaml` add it in

7. Create file `api-server-fip.yaml` using `sops api-server-fip.yaml`. Add the following config:

```yaml
stfc-cloud-openstack-cluster:
  openstack-cluster:
      apiServer:
          # create a floatip for accessing your K8s cluster and put it here
          floatingIP: 130.xxx.yyy.zzz 
```

This file contains the floating ip in which Kubernetes API server can be accessed

8. Create file `app-creds.yaml` using `sops app-creds.yaml`. Add the following config

```yaml
stfc-cloud-openstack-cluster:
  openstack-cluster:
      # COPY YOUR OPENSTACK APP-CREDS INFO HERE

      # IT SHOULD LOOK LIKE THIS

      clouds:
          openstack:
              auth:
                  auth_url: ""
                  application_credential_id: ""
                  application_credential_secret: ""

                  # REMEMBER TO ADD THE PROJECT_ID MANUALLY
                  project_id: ""
                  
              region_name: ""
              interface: ""
              identity_api_version: ""
              auth_type: ""

```

This file contains the credentials for creating and managing that cluster on openstack

> [!CAUTION]
> Make sure the files in steps 7 and 8 has been **encrypted** using SOPS as outlined in the steps above before committing and pushing changes to your branch.

> [!NOTE]
> The application credential must be created and valid for the project you want to created the child cluster in. It does not need to point to the same project as the management cluster.

9. (Optional 9-12) Create a new folder under `clusters/<environment>/<cluster-name>/secrets/apps`
You only need to do this if you need to setup secrets for any apps you want to install onto the new child cluster 

10. Create an age key for your new cluster to read any app-specific secrets
See [Secrets](secrets.md) for more information on Sops Secrets

11. Create `.sops.yaml` and add newly created public age key for new cluster
Add your own and any other public age keys as necessary
  - (PROD/STAGING ONLY) - only add the relevant singular rotate keys
  - (DEV ONLY) - add age keys of all cloud-team members - as it's easier to review and make changes
 
12. Add in encrypted secret files as needed  
> [!CAUTION]
> Make sure every file added has been **encrypted** using SOPS as outlined in the steps above before committing and pushing changes to your branch.

13. You can now setup you cluster to deploy applications - see [Deploying Apps onto a cluster](./deploying-apps.md)

14.   Make a PR and get it reviewed.

15.  Once merged, your new cluster should spin into life

16.  Grab the kubeconfig from the management cluster 
``` clusterctl get kubeconfig <environment>-<cluster-name>-cluster -n clusters > ~/.kube/config ```

17.  (On completing 9-12) Run the script `./deploy-helm-secret.sh` to deploy your newly generated age key onto the cluster  

```cd ./scripts; ./deploy-helm-secret.sh <path-to-age-key>```

> [!NOTE] 
> See deploying apps to deploy ArgoCD and apps to new cluster


## Deploying ArgoCD to a fresh cluster

If you want to deploy apps to newly created cluster, you need to follow the steps in [Deploying Apps](./deploying-apps.md) 

Once you complete these steps you will need to run `./scripts/deploy.sh <cluster-name> <environment>` on your cluster to spin up argocd and any apps you've configured to run
