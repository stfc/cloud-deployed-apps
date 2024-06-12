# Deploying a New App Onto a Cluster

## Prerequisites 

- Chart for the application
  - This must be defined in `charts/<environment>/<chart-name>`, where `<environment>` is the environment of the cluster (e.g. dev/staging) you want to deploy the app to
  - See [Charts](charts.md) for more information


- Understanding of core ArgoCD Concepts: See [ArgoCD Concepts](https://argo-cd.readthedocs.io/en/stable/core_concepts/)
  - In particular [ApplicationSets](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/) 

To deploy a new app onto the cluster - make sure a chart exists for it.  

## Steps

1. Make a branch for your changes

2. Edit the `apps.yaml` file to add a new app. 
   - make a change to `ApplicationSet` with the `metadata.name` entry matching `<cluster-name>-apps` 
   - where `<cluster-name>` is the name of the cluster

To add an app provide the following
```
spec:
  generators:
    - list:
        elements:

        ...
        - name: "app-name" 

        # NAME OF CHART - should be in charts/<environment>/chart-name
          chartName: "chart-name" 

        # THIS NEEDS TO BE INCLUDED - NON-OPTIONAL (but can be blank)
        # PATH TO CLUSTER-SPECIFIC CHART VALUES HERE (relative to chart location in repo)
          valuesFile: ../../../clusters/<environment>/<cluster-name>/<cluster-specific-values-file>.yaml

```

> [!NOTE]
> IGNORE THE EXISTING ELEMENTS

`name`: name of ArgoCD-Application

`chartName`: name of chart - matching directory name should be in `charts/<environment>/`

`valuesFile`: path to cluster-specific values file for chart (relative to chart location in repo)

    - NOTE: this `valuesFile` parameter is NON-OPTIONAL - you must provide a file, even if its blank

> [!NOTE]
> Remember to encase any cluster-specific values for the chart in the sub-chart name to which they apply. E.g. for argo-cd values - they should be defined like: 

```
argo-cd:
   val1: foo
   val2: bar
```

This is because `argo-cd` is the name of the subchart that installs argocd

3. Commit and make a PR

4. Once its merged, the new application to spring to life