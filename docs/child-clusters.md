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
5. Create an age key for your new cluster to read any app-specific secrets

It could look like this:

```yaml
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

5. Create a new folder under `secrets/infra/<environment>/<cluster-name>`

6. Create a new `.sops.yaml` file or copy one from another cluster from the same environment 
See [Secrets](secrets.md) for more information

In this file you will define age **public** keys for those who can decrypt/encrypt secrets belonging to that cluster

> [!NOTE]
> Make sure that the management cluster for the same environment can decrypt those secrets
> Make sure that the management cluster's public key is added to `.sops.yaml`


7. Create file `api-server-fip.yaml` using `sops api-server-fip.yaml`. Add the following config:

```yaml
openstack-cluster:
    apiServer:
        # create a floatip for accessing your K8s cluster and put it here
        floatingIP: 130.xxx.yyy.zzz 
```

This file contains the floating ip in which Kubernetes API server can be accessed

8. Create file `app-creds.yaml` using `sops app-creds.yaml`. Add the following config

```yaml
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

9. Make a PR and get it reviewed.

10. Once merged, your new cluster should spin into life

11. Grab the kubeconfig from the management cluster 
``` clusterctl get kubeconfig <environment>-<cluster-name>-cluster -n clusters > ~/.kube/config ```

12. (Optional) Run the script `./deploy-helm-secret.sh` to deploy your newly generated age key onto the cluster 
  - only need to run this if the charts you want to deploy require secrets

13. (On completing 12) Create the directory `./secrets/apps/<environment>/<clustername>` and create a `.sops.yaml` file and add the **public** key of your generated age file

14. (On completing 13) Add any other age keys that you want to grant access to these secrets 
  - (PROD/STAGING ONLY) - only add the relevant singular rotate keys
  - (DEV ONLY) - add age keys of all cloud-team members - as it's easier to review and make changes

```cd ./scripts; ./deploy-helm-secret.sh <path-to-age-key>```

> [!NOTE] 
> See deploying apps to deploy ArgoCD and apps to new cluster


## Deploying ArgoCD to a fresh cluster

If you want to deploy apps to newly created cluster, you need to follow the steps in [Deploying Apps](./deploying-apps.md) 

Once you complete these steps you will need to run `./scripts/deploy.sh <cluster-name> <environment>` on your cluster to spin up argocd and any apps you've configured to run
