# Deploying a child cluster on an existing environment

> [!NOTE]
> The following documentation outlines how to deploy child clusters in an existing environment.
> See [Deploying a new environment](clusters.md) if deploying a new ArgoCD environment

## Prerequisites: 
1. Create an application credential for your new cluster on your project
2. Ensure enough quota for the cluster (RAM, CPU, instances etc)
3. Provision a floating ip on your project for kubernetes API Server access
4. (Optional) Provision a second floating IP for nginx ingress controller

## Steps
To deploy a new child cluster on an existing environment follow these steps:


1. Create a branch off of main
2. Create a new folder under `clusters/<environment>/<cluster-name>`
3. Create a file in `clusters/<environment>/<cluster-name>/infra-values.yaml` 
4. Populate the `infra-values.yaml` file with cluster-specific values for the chart in `capi-infra` chart. 
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

5. Create a new folder under `secrets/<environment>/<cluster-name>`

6. Create a new `.sops.yaml` file or copy one from another cluster from the same environment 
See [Secrets](secrets.md) for more information

In this file you will define age **public** keys for those who can decrypt/encrypt secrets belonging to that cluster

> [!NOTE]
> Make sure that the management cluster for the same environment can decrypt those secrets
> Make sure that the management cluster's public key is added to `.sops.yaml`


7. Create file `api-server-fip.yaml` using `sops api-server-fip.yaml`. Add the following config:

```
openstack-cluster
    apiServer:
        floatingIP: 130.xxx.yyy.zzz
```

This file contains the floating ip in which Kubernetes API server can be accessed

8. Create file `app-creds.yaml` using `sops app-creds.yaml`. Add the following config

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

> [!CAUTION]
> Make sure the files in steps 7 and 8 has been **encrypted** using SOPS as outlined in the steps above before committing and pushing changes to your branch.


> [!NOTE]
> The application credential must be created and valid for the project you want to created the child cluster in. It does not need to point to the same project as the management cluster.

9. Make a PR and get it reviewed.

10.  Once merged, your new cluster should spin into life
