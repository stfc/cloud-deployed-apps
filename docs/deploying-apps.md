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

2. Create/Edit the `apps.yaml` file on the cluster you want to add a new app to. (Copy and modify an existing apps.yaml from another cluster - remember to change all relevant filepaths to point to your cluster's sub-directory) 
   - make a change to `ApplicationSet` with the `metadata.name` entry matching `<cluster-name>-apps` 
   - where `<cluster-name>` is the name of the cluster

To add an app provide the following

```yaml
spec:
  generators:
    - list:
        elements:

        ...
        - name: "app-name" 

        # NAME OF CHART - should be in charts/<environment>/chart-name
          chartName: "chart-name" 

        # OPTIONAL
        # PATH TO CLUSTER-SPECIFIC CHART VALUES HERE
        # (relative to chart location in repo)
          valuesFile: ../../../clusters/<environment>/<cluster-name>/<cluster-values-file>.yaml
        
        # OPTIONAL
        # PATH TO ANY SECRETS - see app-specific docs to see if any secrets are needed
        # (relative to chart location in repo)
          secretsFile: ../../../secrets/apps/<environment>/<cluster-name>/<secrets-file>.yaml

```

`name`: name of ArgoCD-Application

`chartName`: name of chart - matching directory name should be in `charts/<environment>/`

`valuesFile`: path to cluster-specific values file for chart (relative to chart location in repo)

`secretsFile`: path to cluster-specific secrets for a chart (relative to chart location in repo)
    
    - NOTE: tempalate for Chart secrets can be found in `charts/<environment>/<chartname>/secrets-templates`

> [!NOTE]
> Remember to encase any cluster-specific values and secrets for the chart in the sub-chart name to which they apply. E.g. for argo-cd values - they should be defined like: 

```yaml
argo-cd:
   val1: foo
   val2: bar
```

This is because `argo-cd` is the name of the subchart that installs argocd

4. Populate and encrypt any secrets needed for the chart - see [Secrets](./secrets.md) 

5. Commit and make a PR