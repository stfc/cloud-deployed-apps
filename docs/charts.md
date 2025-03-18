# Charts Directory

In this section we will outline what the charts directory is and how to modify it.

The Charts directory is a workaround for ArgoCD to work properly with upstream helm charts

[Argocd multiple sources](https://argo-cd.readthedocs.io/en/stable/user-guide/multiple_sources/) and [Sops secrets](https://github.com/jkroepke/helm-secrets/wiki/ArgoCD-Integration) cannot be used together
    - see issue [11866](https://github.com/argoproj/argo-cd/issues/11866), and PR [11966](https://github.com/argoproj/argo-cd/pull/11966)

Charts directory contains boilerplate "wrapper" charts. For each app argocd manages, there is a "wrapper" chart - which just installs the corresponding upstream chart as a "dependency" - allowing ArgoCD to function


## Directory Structure
The `charts` directory is subdivided into environment they can be installed on. 

Each application should have its own chart directory under `charts` for the environment they are to be used on. 
Where possible an application should have a chart in all environments (dev, staging and prod)

The `staging` and `prod` environments are special. These should not be edited directly by developers, instead changes are
copied from `dev` to `staging` and `prod` as part of the release process without modification. This is further described later in the documentation - see [promotion workflow](promotion.md).

## Chart structures
Each chart contains `Chart.yaml` 
- `version` of the chart is not used or important
- `dependencies` should be to an upstream chart - in [cloud helm charts](https://github.com/stfc/cloud-helm-charts) or another upstream chart

Nothing else should go here - DO NOT PUT VALUES HERE - they should go in [cloud helm charts](https://github.com/stfc/cloud-helm-charts) or `clusters/<env>/_shared` 

If its a chart from [cloud helm charts](https://github.com/stfc/cloud-helm-charts) - consult the corresponding README docs

Only the `argocd` chart has `values.yaml` which can be edited

## Updating/testing versions

To test a new version of a chart - use the dev environment. 
Make a PR to change the dependency version in `Chart.yaml`. see [Promotion Workflow](promotion.md) for more info

- Staging should automatically pick up new version changes
- Prod promotion will happen automatically 

## Deploying a new app, or modifying an existing app

> [!NOTE]
> Only upstream charts are allowed - if this is a new chart - upload it to [cloud helm charts](https://github.com/stfc/cloud-helm-charts)

1. Create a branch for development off of `main` for making changes

2. Create a new directory under `charts/dev` (or similar) for your new chart 

3. Create `Chart.yaml`add your Chart as a dependency under `dependencies`
    - `name` must match directory name
    - `version` doesn't matter

4. Create a PR and get it reviewed and merged

5. Then you can deploy the chart - see [Deploying Apps to a cluster](deploying-apps.md) - setting cluster/environment specific values as needed