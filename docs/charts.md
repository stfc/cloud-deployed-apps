# Charts Directory

In this section we will outline how to modify or add new charts to this repo for argocd to potentially manage for a cluster.

This repository uses folder-based revision management to manage the helm charts that argocd will manage. This avoids
us having to reconcile git branches, and the current HEAD of the repo is always the current state of the cluster.

## Directory Structure
Each application should have its own chart directory under `charts/dev` (or a similar directory for other environments).

The `staging` and `prod` environments are special. These should not be edited directly by developers, instead changes are
copied from `dev` to `staging` and `prod` as part of the release process without modification. This is further described later in the documentation.

## Chart structures
Each chart contains:

- `Chart.yaml` - which is boilerplate, the version of the chart is not currently used.
- `requirements.yaml` - this should contain the upstream chart(s) and versions. See [Helm Documentation](https://v2.helm.sh/docs/developing_charts/#managing-dependencies-with-requirements-yaml)
(NOTE: `requirements.yaml` is deprecated and will be merged into `Charts.yaml`)
- `values.yaml` files that applies to all environments, but are tailored to our platform.

Note: environment specific values, e.g. domain names, go alongside the AppSet in the [TODO] directory.
This allows us to copy the chart from `dev` to `staging` and `prod` without modification.

## Promoting changes to staging and prod

Changes are promoted as-is from a developers environment (e.g. `charts/dev`) to the staging environment initially, then prod later.
This can be done in one of two ways

- Single application. Useful for security patches, targeted changes, or hot-fixes.
- Full release. This is preferred, where all changes are promoted at once on a scheduled basis.

Note: Applications can be held back from a full release if required, e.g. if a platform is in change-freeze during a "full" release.

## Deploying a new app, or modifying an existing app

- Create a branch for development off of `main` for making changes
- Create a new directory under `charts/dev` (or similar) for your new chart
- Simply use `helm install` to install the chart on a test cluster to see if it works, iterating on the chart until it does.
- Note any environment specific values that cannot ever be shared between environments, e.g. domain name, monitoring....etc.
- Remove these values and add them into the specific cluster's values file as described in [TODO]
- Follow the instructions for adding your application to the appset as described in [TODO]
- Create a PR
