# Deploying a New App Onto a Cluster

## Prerequisites 

- Chart for the application
  - This must be defined in `charts/<environment>/<chart-name>`, where `<environment>` is the environment of the cluster (e.g. dev/staging) you want to deploy the app to
  - See [Charts](charts.md) for more information


- Understanding of core ArgoCD Concepts: See [ArgoCD Concepts](https://argo-cd.readthedocs.io/en/stable/core_concepts/)
  - In particular [ApplicationSets](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/applicationset-specification/) 

To deploy a new app onto the cluster - make sure a chart exists for it.  

## Steps

> [!NOTE]
> Make sure you inform DevOps team that you're deploying a new application onto staging

> [!NOTE]
> Only upstream charts are allowed - if this is a new chart - you might want to upload it to [cloud helm charts](https://github.com/stfc/cloud-helm-charts) and make sure you

> [!NOTE]
> You should test your chart modifications/additions by deploying it onto a local/dev CAPI cluster first and making sure it works

> [!NOTE]
> You might want to silence staging alerts during this period

1. Create a branch for development off of `main` for making changes `dev/new-feature`

2. Create a new directory under `charts/staging` for your new chart 

3. Create `Chart.yaml`add your Chart as a dependency under `dependencies`
    - `name` must match directory name
    - `version` doesn't matter

4. **Next, To test and tweak your changes**. Create a branch for `dev/new-feature-test-deployment` off of `dev/new-feature`

5. Change any mention of `targetRevision: main` to `targetRevision: dev/new-feature-test-deployment` in `clusters/staging/worker/apps.yaml`

6. Add your app to `staging` - setting cluster/environment specific values as needed

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
        # PATH TO ANY CLUSTER-SPECIFIC SECRETS - see upstream chart docs to see if any secrets are needed
        # (relative to chart location in repo)
          secretsFile: ../../../clusters/<environment>/<cluster-name>/secrets/apps/<secrets-file>.yaml

        # OPTIONAL
        # PATH TO ANY ENVIRONMENT-SPECIFIC VALUES - see upstream chart docs to see if any secrets are needed
        # (relative to chart location in repo)
          sharedValuesFile: ../../../clusters/<environment>/_shared/<shared-values-file>.yaml
        
        # OPTIONAL
        # PATH TO ANY ENVIRONMENT-SPECIFIC SECRET VALUES - see upstream chart docs to see if any secrets are needed
        # (relative to chart location in repo)
          sharedValuesFile: ../../../clusters/<environment>/_shared/secrets/<shared-secrets-file>.yaml

```

`name`: name of ArgoCD-Application

`chartName`: name of chart - matching directory name should be in `charts/<environment>/`

`valuesFile`: path to cluster-specific values file for chart (relative to chart location in repo)

`secretsFile`: path to cluster-specific secrets for a chart (relative to chart location in repo)
    
    - NOTE: tempalate for Chart secrets can be found in `charts/<environment>/<chartname>/secrets-templates`

`sharedValuesFile`: path to environment-specific values file for chart 
  - shared values that apply to all instances of the chart running on environment

`sharedSecretsFile`: path to any environment-specific secrets for chart
  - shared secrets that apply to all instances of the chart running on environment


> [!NOTE]
> Remember to encase any values and secrets for the chart in the sub-chart name to which they apply. E.g. for argo-cd values - they should be defined like: 

```yaml
argo-cd:
   val1: foo
   val2: bar
```

This is because `argo-cd` is the name of the subchart that installs argocd

7. Point `staging` to your test-deployment brnach by editing `targetRevision` to `dev/new-feature-test-deployment` for cloud-deployed-apps app on the [Web UI](https://argocd.staging-worker.nubes.stfc.ac.uk/applications/argocd/cloud-deployed-apps?view=tree&resource=&node=argoproj.io%2FApplication%2Fargocd%2Fcloud-deployed-apps%2F0)

8. Make changes and commit to `dev/new-feature` branch as needed, when you need to test, rebase `dev/new-feature-test-deployment` onto the branch and push changes - staging worker should automatically pick up changes

9.  Create a PR for `dev/new-feature`, get it reviewed and merged  

10. Once merged into `main` you can repoint `staging` back to `main` by editing `targetRevision` on the [Web UI](https://argocd.staging-worker.nubes.stfc.ac.uk/applications/argocd/

11. Make a branch for your changes

12. Create/Edit the `apps.yaml` file on the cluster you want to add a new app to. (Copy and modify an existing apps.yaml from another cluster - remember to change all relevant filepaths to point to your cluster's sub-directory) 
   - make a change to `ApplicationSet` with the `metadata.name` entry matching `<cluster-name>-apps` 
   - where `<cluster-name>` is the name of the cluster

# Updating/testing versions of Existing Apps

1. Release a new version of the chart in [cloud helm charts](https://github.com/stfc/cloud-helm-charts).
   - Test this on a dev/local cluster to make sure it works
2. Run GitHub Action "Update Helm Chart Dependencies on Dev", or wait for it to automatically run 
3. tweak cluster-specific values for `staging` cluster for the service if necessary
4. Merge created PR to change the dependency version in staging `chart` 
5. New version to sync automatically and begin running on staging - keep an eye on alerts and the service, if it fails, you might need to:
   - rollback the merge, resync changes
   - tweak the cluster-specific values as needed
   - re-merge, repeat the steps until it works
6. Perform long-term user-acceptance testing on staging
7. CI/CD job for promotion to prod to will happen automatically, but you can force it by manually running "Promote Staging to Prod" Github Action 
