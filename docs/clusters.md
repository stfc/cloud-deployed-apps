# Deploying a child cluster on an existing environment

## Prerequisites: 
1. Create an application credential for your new cluster on your project
2. Ensure enough quota for the cluster (RAM, CPU, instances etc)
3. Provision a floating ip on your project for kubernetes API Server access
4. (Optional) Provision a second floating IP for nginx ingress controller

## Steps
To deploy a new child cluster on an existing environment follow these steps:


1. create a branch off of main
2. create a new folder under `clusters/<environment>/<cluster-name>`
3. create a file in `clusters/<environment>/<cluster-name>/infra-values.yaml` 
4. populate the `infra-values.yaml` file with cluster-specific values for the chart in `capi-infra` chart. 
It could look like this:
```
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

# addon config for the cluster - here we're defining an nginx ingress controller service
  addons:
    ingress:
      enabled: true
      nginx:
        release:
          values:
            controller:
              service:
                loadBalancerIP: "130.xxx.yyy.zzz"

```

5. create a new folder under `secrets/<environment>/<cluster-name>`

6. create a new `.sops.yaml` file or copy one from another cluster from the same environment 
See [Secrets](secrets.md) for more information

In this file you will define age public keys for those who can decrypt/encrypt secrets belonging to that cluster
NOTE: Make sure that the management cluster for the same environment can decrypt those secrets. Make sure that the management cluster's public key is added to `.sops.yaml`

7. create file `api-server-fip.yaml` using `sops api-server-fip.yaml`. Add the following config

```
openstack-cluster
    apiServer:
        floatingIP: 130.xxx.yyy.zzz
```

This file contains the floating ip in which Kubernetes API server can be accessed

8. create file `app-creds.yaml` using `sops app-creds.yaml`. Add the following config

```
openstack-cluster:
    # COPY YOUR OPENSTACK APP-CREDS INFO HERE

    # IT SHOULD LOOK LIKE THIS

    clouds:
        openstack:
            auth:
                auth_url: ""
                application_credential_id: ""
                application_credential_secret: ""

                # ADD THE PROJECT_ID MANUALLY
                project_id: ""
                
            region_name: ""
            interface: ""
            identity_api_version: ""
            auth_type: ""

```

This file contains the credentials for creating and managing that cluster on openstack

NOTE: the application credential must be created and valid for the project you want to create the cluster on
NOTE: the application credential does not need to point to the same project that the management cluster is running on

9. Make a PR and get it reviewed.

10.  Once merged, your new cluster should spin to life


# Deploying a new environment

## Prerequisites: 
1. Create an application credential for your new cluster on your project
2. Ensure enough quota for the cluster (RAM, CPU, instances etc)
3. Provision a floating ip on your project for kubernetes API Server access
4. (Optional) Provision a second floating IP for nginx ingress controller
5. Create a self-managed cluster called `management` 
   - see https://stfc.atlassian.net/wiki/spaces/CLOUDKB/pages/211878034/Cluster+API+Setup. 
   - Ensure the name is `management` as CAPI cannot rename a cluster.

## Motivation
You may want to make your own environment so you can test gitOps config or charts idependently of running clusters on test/feature branches

We don't want too many environments on `main` - especially those that aren't being used so there's less clutter

## Steps
To deploy another environment - follow these steps: 

1. create a new branch for your work

2. create a new folder `charts/<your-environment>`

3. copy the charts from another environment - from either `prod`, `dev`, or `staging`. 

4. create a new folder `clusters/<your-environment>`

5. copy `management` subfolder from another environment into your newly created folder in `clusters`. 
You can optionally copy or create any other cluster subfolders you want to be in this environment here as well

6. edit `apps.yaml`: 

- any entries that begin with `path` should use charts from the new environment
- any entries that begin with `valuesFiles` should use paths from the new environment
  
- (Optional) any entries with `targetRevision` or `revision` should point to your new branch if you are using this branch for testing or as a feature branch and not intending on keeping it long-term

7. modify the `infra-values.yaml` and any other cluster-specific values files as required 
- see [infra-setup](infra-setup.md) - "Pre-deployment" Steps

8. modify/add any cluster-specific values for any apps you want to manage.
- see [app-setup](app-setup.md) - "Pre-deployment" Steps

9.  create a new folder `secrets/<your-environment>` and subfolder `secrets/<your-environment>/management` 
You will also need to create another subfolder for each extra cluster subfolder you've copied/added

10. Add secret files `.sops.yaml`, `api-sever-fip.yaml`, and `app-creds.yaml` as above 
See (Deploying a child cluster on an existing environment steps 5-7). 
Repeat for all other clusters you want to add

11.   (Optional) If this is not a temporary environment - and you want to keep it around long term in `main` make a PR for it and get it merged

12.   Deploy age private key secret to management cluster - see [secrets](secrets.md) for more info
``` cd scripts; ./deploy-helm-secret.sh <path-to-age-private-key>``` 

13.   Run deploy.sh on your self-managed cluster `management` like so:
``` cd scripts; ./deploy.sh <cluster-name> <your-environment> ```

14.  Wait for argocd to deploy and it should spring to life and spin up any other clusters you've defined

15.  Perform any Post-Deployment steps - see [infra-setup](infra-setup.md) and [app-setup](app-setup.md) for any apps you want to manage

16.  Repeat step 12-14 for each extra cluster that you have running that you want to manage apps with
    - you can get the kubeconfig to access these clusters by accessing the `management` cluster and running `clusterctl get kubeconfig $CLUSTER_NAME -n clusters > $CLUSTER_NAME.kubeconfig`