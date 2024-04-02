# Deploying Infrastructure

This document outlines how to deploy infrastructure, as well as pre-deployment and post-deployment steps to setup "infra" charts on a cluster.

## Managing Infra for a cluster

To add/edit infrastructure charts for a cluster, you'll want to edit the file `infra-values.yaml` 

make sure that global configuration is set at the top of the file

```
global:
  # name of the cluster 
  # MUST MATCH THE DIRECTORY NAME
  clusterName: test-cluster

  spec:
    source:
      targetRevision: <your branch>

      # change this if you're using a fork
      repoURL: https://github.com/stfc/cloud-deployed-apps.git 

      # namespace where the argocd applications will be installed to 
      namespace: argocd

```

then you can add infra like so:

```
infra:
  # name of argocd application
  - name: infra-1

    # when true, will disable auto-sync and auto-heal on the argocd app
    disableAutomated: false

    # name of the chart to install - corresponds with chart name in charts/infra/
    chartName: capi

    # namespace where the chart contents will be installed to
    namespace: clusters

    # a list of filepaths to cluster-specific values for a given chart
    # overrides defaults set for that chart
    additionalValueFiles: 
      - clusters/test-cluster/overrides/infra/infra1.yaml

    # (optional) can define the git SHA to sync against specific to the app
    # This overrides global.spec.source.targetRevision
    # targetRevision: <other-branch>
```
#
# Chart Specific Documentation

# CAPI

The `capi` chart  is used to configure and manage a CAPI cluster itself and any child clusters.  

Cluster API is a tool for provisioning, and operating K8s clusters. We use this tool to run K8s on Openstack. We utilise StackHPCs CAPI Chart to do this - https://github.com/stackhpc/capi-helm-charts

## Pre-deployment steps 


**For self-managed cluster**
 
1. Make a note of the floating ip for the cluster's ApiServer.

2. Provision (or make note of if already provisioned) a floating ip for nginx ingress controller

**NOTE: By default we enable nginx ingress controller, you can turn this off and skip this step but it's not recommended.**

3. create an file in `overrides/` (if not already done so) and set `cloudCredentialsSecretName: <name-of-cluster>-cloud-credentials` 

**For child cluster**

1. Ensure that there is enough quota on your project to create the child cluster
    - The child cluster will also require 2 new floating IPs that it will automatically provision

2a. (Optional) create a new clouds.yaml credentials secret for your child cluster 

`kubectl create secret generic <secret-name> --from-file=cacert=./cacert.txt --from-file=clouds.yaml=./clouds.yaml -n clusters`

- `cacert.txt` is the certificate set here - https://github.com/stfc/cloud-capi-values/blob/master/values.yaml#L6-L130 

- `clouds.yaml` is the application credential you want to use for setting up child cluster

2b. (Alternatively) you can re-use the management cluster secret

1. create a file in `overrides/` (if not already done so) for the child cluster and set `cloudCredentialsSecretName: <name-of-management-cluster>-cloud-credentials` 


NOTE: we cannot specify the child cluster to use specific floating ips yet - this requires an upstream fix to allow setting these attributes from secrets.
  

## Post-deployment

Once you deploy this application - see [Deploying Cluster](./DEPLOYING_CLUSTER.md) - You need to manually set the floating ip for the APIServer and nginx ingress controller

**For self-managed cluster**

create a temporary file `/tmp/capi_patch.yaml`

```
spec:
  source:
    helm:
      parameters:
      - name: openstack-cluster.apiServer.floatingIP
        value: <APIServer floating ip here>
      - name: openstack-cluster.addons.ingress.nginx.release.values.controller.service.loadbalancerIP
        value: <nginx ingress controller floating here>
```

then you can run: 
`kubectl patch -n argocd app <cluster-name> --patch-file /tmp/capi_patch.yaml --type merge`

**For child cluster**

You'll need to do the same as above but with the IPs that get automatically provisioned once deployed. You'll have to wait until everything is synced up and green before doing this.  


## Modifying CAPI Values


See https://github.com/stackhpc/capi-helm-charts for a full rundown of changes that you can make. 

This chart also installs various other "addons" that can also be configured - see https://github.com/stackhpc/capi-helm-charts/tree/main/charts/cluster-addons

The ones that you'd likely change often include:

  - kube-prometheus-stack monitoring - see https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/

  - loki logging - see https://github.com/grafana/helm-charts/tree/main/charts/loki-stack

#### Examples:

To change the flavor name for instance - make a cluster-specific file and place in `clusters/<cluster-name>/overrides/capi-overrides.yaml` 

```
# capi-overrides.yaml

openstack-cluster:
  nodeGroupDefaults:
    machineFlavor: l3.tiny   

  controlPlane: 
    machineFlavor: l3.micro 

```

and add it to `.additionalValueFiles` in `clusters/<cluster-name>/values.yaml` like so

```
# values.yaml

# since capi is an infra chart
infra:
  # name should match so it will self-manage
  - name: <cluster-name>
    chartName: capi
    ...
    additionalValueFiles:
       # path starts from root of repo
       - clusters/<cluster-name>/overrides/capi-overrides.yaml

```


**NOTE** The name of the override file here is just an example 
   - it is left to you and repo maintainers to determine how best to organise override files

