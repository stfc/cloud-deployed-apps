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
    # this is useful for testing version upgrades on the chart
    # This overrides global.spec.source.targetRevision
    # targetRevision: <other-branch>
```
#
# Chart Specific Documentation

# CAPI

The `capi` chart  is used to configure and manage a CAPI cluster itself and any child clusters.  

Cluster API is a tool for provisioning, and operating K8s clusters. We use this tool to run K8s on Openstack. 

We utilise StackHPCs CAPI Chart to do this. See the docs [here](https://github.com/stackhpc/capi-helm-charts)

## Pre-deployment steps 


**For self-managed cluster**
 
1. Make a note of the floating ip for the cluster's ApiServer.

2. Provision (or make note of if already provisioned) a floating ip for nginx ingress controller

**NOTE: By default we enable nginx ingress controller, you can turn this off and skip this step but it's not recommended.**

3. create an file in `clusters/<cluster-name>/overrides/infra/deployment.yaml` (if not already done so) and set the following value: 

```
openstack-cluster:
  cloudCredentialsSecretName: <name-of-cluster>-cloud-credentials` 
  
  # define any cluster-specific capi values here 
```

**For child cluster**

1. Ensure that there is enough quota on your project to create the child cluster. The child cluster will also require a new floating IP that it will automatically provision


2. Create a new clouds.yaml credentials secret for your child cluster. 

(Alternatively) you can re-use the management cluster secret - NOT RECOMMENDED. 
```
kubectl create secret generic <secret-name> --from-file=cacert=./cacert.txt --from-file=clouds.yaml=./clouds.yaml -n clusters
```

`cacert.txt` is the certificate set here - https://github.com/stfc/cloud-capi-values/blob/master/values.yaml#L6-L130. Copy this and create a file `/tmp/cacert.txt`

`clouds.yaml` is the application credential you want to use for setting up child cluster

3. Create a file in `clusters/<cluster-name>/overrides/infra/deployment.yaml` (if not already done so) for the child cluster and set the following value:
```
openstack-cluster:
  cloudCredentialsSecretName: <secret-name>
  
  # define any cluster-specific capi values here 
```

**NOTE: we cannot specify the child cluster to use specific floating ips yet - this requires an upstream fix to allow setting these attributes from secrets.**

## Setup Nginx Ingress and TLS

1. Specify FIP for Nginx Ingress

nginx-ingress is enabled by default and so if you want it you can enable it and define the floating IP that it should use. Edit the file `deployment.yaml` and add the following

```
openstack-cluster:
  addons:
    ingress:
      enabled: true
      nginx:
        release:
          values:
            controller:
              service:
                loadBalancerIP: "xxx.xxx.xxx.xxx"
```

2. Add TLS Certs

CAPI monitoring (which is enabled by default) requires TLS certs. 

Create a self-signed cert or get one issued. 

To create a self-signed cert:

```
openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -keyout privateKey.key -out certificate.crt
```

Then to create a secret from a cert - the secret name is for Prometheus, Alertmanager and Grafana is expected to be `tls-keypair` by default:

```
kubectl create secret tls tls-keypair --cert certificate.crt --key pivateKey.key -n monitoring-system
```

## Optional Steps

1. (optional) Enable sending monitoring alerts

Monitoring is enabled by default but will not send alerts out unless configured to. 
In order to turn on alerts - edit the file `deployment.yaml` and add the following

```
openstack-cluster:
  addons:
    monitoring:
      kubePrometheusStack:
        release:
          values:
            alertmanager:
              enabled: true
```

2. (optional) Change the ingress hostnames and or certs for monitoring endpoints

```
openstack-cluster:
  addons:
    monitoring:
      kubePrometheusStack:
        release:
          values:
            alertmanager:
              ingress:
                hosts:
                  - <alertmanager-hostname>.nubes.stfc.ac.uk
                tls:
                  - hosts: 
                    - <alertmanager-hostname>.nubes.stfc.ac.uk
                    secretName: tls-keypair
            prometheus:
              ingress:
                hosts:
                  - <prometheus-hostname>.nubes.stfc.ac.uk
                tls:
                  - hosts: 
                    - <prometheus-hostname>.nubes.stfc.ac.uk
                    secretName: tls-keypair
            grafana:
              ingress:
                hosts:
                  - <grafana-hostname>.nubes.stfc.ac.uk
                tls:
                  - hosts: 
                    - <grafana-hostname>.nubes.stfc.ac.uk
                    secretName: tls-keypair
``` 

**NOTE: make sure you follow the post-deployment steps too to configure sending emails**

## Post-deployment

You need to manually set a few secrets that capi requires - this includes: 
1. The floating ip for the APIServer
2. (Optional) The mail server to use to send alerts (If sending alerts)
3. (Optional) Which email address to send alerts to. (If sending alerts)

**For self-managed cluster**

create a temporary file `/tmp/capi_patch.yaml`

```
spec:
  source:
    helm:
      parameters:
      - name: openstack-cluster.apiServer.floatingIP
        value: <APIServer floating ip here>
      - name: >-
          openstack-cluster.addons.monitoring.kubePrometheusStack.release.values.alertmanager.config.global.smtp_smarthost
        value: <hostname>:<port>
      - name: >-
          openstack-cluster.addons.monitoring.kubePrometheusStack.release.values.alertmanager.config.receivers[1].email_configs[0].to
        value: <email-address>
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

