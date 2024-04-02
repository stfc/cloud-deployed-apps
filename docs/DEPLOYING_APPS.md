# Deploying Apps

This document outlines how to deploy infrastructure, as well as pre-deployment and post-deployment steps to setup "app" charts on a cluster.

## Managing Apps for a cluster

To add/edit infrastructure charts for a cluster, you'll want to edit the file `app-values.yaml` 

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

then you can add apps like so:

```
apps:
  # name of argocd application
  - name: app-1

    # when true, will disable auto-sync and auto-heal on the argocd app
    disableAutomated: false

    # name of the chart to install - corresponds with chart name in charts/apps/
    chartName: app1

    # namespace where the chart contents will be installed to
    namespace: app-ns

    # a list of filepaths to cluster-specific values for a given chart
    # overrides defaults set for that chart
    additionalValueFiles: 
      - clusters/test-cluster/overrides/apps/app1-overrides.yaml

    # (optional) can define the git SHA to sync against specific to the app
    # This overrides global.spec.source.targetRevision
    # targetRevision: <other-branch>
```

**NOTE: `app-values.yaml` is required even if no apps are being deployed - this is because argocd will always be self-managed as an app for the cluster**

## Configuring ArgoCD

To configure argocd there is a special `argocd-values.yaml` for each cluster. 
This is used to setup self-managed argocd. 

One of the main reasons you'll want to configure argocd is to change the domain name. You can do this like so:

```
argo-cd:
  global: 
    # default is argocd.example.com
    domain: "argocd.example.io" 
```

## Chart Specific Documentation
No apps yet!