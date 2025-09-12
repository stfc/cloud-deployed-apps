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
