# Charts Directory

In this section we will outline how to modify or add new charts to this repo for argocd to potentially manage for a cluster.

This repository uses folder-based revision management to manage the helm charts that argocd will manage. This avoids
us having to reconcile git branches, and the current HEAD of the repo is always the current state of the cluster.

## Directory Structure
The `charts` directory is subdivided into environment they can be installed on. 

Each application should have its own chart directory under `charts` for the environment they are to be used on. 
Where possible an application should have a chart in all environments (dev, staging and prod)

The `staging` and `prod` environments are special. These should not be edited directly by developers, instead changes are
copied from `dev` to `staging` and `prod` as part of the release process without modification. This is further described later in the documentation - see [promotion workflow](promotion.md).

## Chart structures
Each chart contains:

- `Chart.yaml` - which is boilerplate, the version of the chart is not currently used.
- `requirements.yaml` - this should contain the upstream chart(s) and versions. See [Helm Documentation](https://v2.helm.sh/docs/developing_charts/#managing-dependencies-with-requirements-yaml). (NOTE: `requirements.yaml` is deprecated and will be merged into `Charts.yaml`)
- `values.yaml` files that applies to all environments, but are tailored to our platform.

Note: environment or cluster specific values, e.g. domain names, do not belong here. See [Deploying Apps to a cluster](deploying-apps.md) for more info on cluster/environment-specific values
We only include values that are generic across all environments here - this allows us to copy the chart from `dev` to `staging` and `prod` without modification.

## Promoting changes to staging and prod

see [Promotion Workflow](promotion.md) for more info

Changes are promoted as-is from a developers environment (e.g. `charts/dev`) to the staging environment initially, then prod later.
This can be done in one of two ways

- Single application. Useful for security patches, targeted changes, or hot-fixes.
- Full release. This is preferred, where all changes are promoted at once on a scheduled basis.

Note: Applications can be held back from a full release if required, e.g. if a platform is in change-freeze during a "full" release.

## Deploying a new app, or modifying an existing app

- Create a test cluster - either a self-managed cluster or a child cluster of dev/management - see [Deploying a new cluster](clusters.md)

- Create a branch for development off of `main` for making changes

- Create a new directory under `charts/dev` (or similar) for your new chart - you can also choose to deploy a new cluster for testing - see [Deploying a new cluster](clusters.md)

- Simply use `helm install` to install the chart on a test cluster to see if it works, iterating on the chart until it does.

- Note: Ensure there are no environment specific values are present in the values file e.g. domain name, monitoring....etc. If you have env specific values we cannot promote by simply copying the charts. As a rule of thumb, if you need to consider a value per cluster (e.g. domain name) place it into the clusters dir

- You should store these values alongside the cluster you are using to test these changes - see [Deploying Apps to a cluster](deploying-apps.md)

- Follow the instructions for adding your application to the appset as described in [Deploying Apps to a cluster](deploying-apps.md)

- Create a PR

- Delete your test cluster

- Follow steps in [promotion workflow](promotion.md) for promoting your new app/app changes to staging and then production