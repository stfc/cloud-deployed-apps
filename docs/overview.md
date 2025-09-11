# How Does this Repo Work?

This repo deploys helm charts onto K8s clusters using a GitOps methodology based on folder-flows alongside ArgoCD.

In this document, we'll go through the structure of this repo and what each part does.

## Charts Structure

In this section we will outline what the charts directory is and how to modify it.

The Charts directory is a workaround for ArgoCD to work properly with upstream helm charts

[Argocd multiple sources](https://argo-cd.readthedocs.io/en/stable/user-guide/multiple_sources/) and [Sops secrets](https://github.com/jkroepke/helm-secrets/wiki/ArgoCD-Integration) cannot be used together
    - see issue [11866](https://github.com/argoproj/argo-cd/issues/11866), and PR [11966](https://github.com/argoproj/argo-cd/pull/11966)

Charts directory contains boilerplate "wrapper" charts. For each app argocd manages, there is a "wrapper" chart - which just installs the corresponding upstream chart as a "dependency" - allowing ArgoCD to function


## Directory Structure
The `charts` directory is subdivided into environment they can be installed on. 

Each application should have its own chart directory under `charts` for the environment they are to be used on. 
Where possible an application should have a chart in all environments (staging and prod)


## CI/CD
This Repository contains 2 main CI/CD pipelines:

1. Pipeline that checks that the latest chart version released in [cloud helm charts](https://github.com/stfc/cloud-helm-charts) is running on `staging` - if not a new PR is made "Update helm chart dependencies" to update staging chart. 
Another CI/CD pipeline checks that the chart version on `prod` matches the `staging` chart version. If not a new "promotion" PR is made


## Chart structures
Each chart contains `Chart.yaml` 
- `version` of the chart is not used or important - it is boilerplate
- `dependencies` should be to an upstream chart - in [cloud helm charts](https://github.com/stfc/cloud-helm-charts) or another upstream chart

Nothing else should go here - DO NOT PUT VALUES HERE - they should go in: 
    - [cloud helm charts](https://github.com/stfc/cloud-helm-charts) for generic values that apply to every deployment of that chart 
      - consult the corresponding README docs on [cloud helm charts](https://github.com/stfc/cloud-helm-charts)
    - or `clusters/<env>/_shared` for generic values that apply to either `prod` or `staging` clusters (or if there's no corresponding chart in [cloud helm charts](https://github.com/stfc/cloud-helm-charts))

Only the `argocd` chart has `values.yaml` which can be edited

## Updating/testing versions

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

## Deploying a new app, or modifying an existing app

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

6. Add your app to `staging` - see [Deploying Apps](./deploying-apps.md) - setting cluster/environment specific values as needed

7. Point `staging` to your test-deployment brnach by editing `targetRevision` to `dev/new-feature-test-deployment` for cloud-deployed-apps app on the [Web UI](https://argocd.staging-worker.nubes.stfc.ac.uk/applications/argocd/cloud-deployed-apps?view=tree&resource=&node=argoproj.io%2FApplication%2Fargocd%2Fcloud-deployed-apps%2F0)

8. Make changes and commit to `dev/new-feature` branch as needed, when you need to test, rebase `dev/new-feature-test-deployment` onto the branch and push changes - staging worker should automatically pick up changes

10. Create a PR for `dev/new-feature`, get it reviewed and merged  

11. Once merged into `main` you can repoint `staging` back to `main` by editing `targetRevision` on the [Web UI](https://argocd.staging-worker.nubes.stfc.ac.uk/applications/argocd/