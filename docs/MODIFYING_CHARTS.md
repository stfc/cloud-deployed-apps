# Adding or Modifying Charts

In this section we will outline how to modify or add new charts to this repo for argocd to potentially manage for a cluster

New charts should go in `apps` or `infra`.  
- if the chart should work on any kubernetes cluster, it belongs in `apps`
- if the chart only works on specific flavor of kubernetes cluster, it belongs in `infra`

Each chart contains:

- `Chart.yaml` - which is boilerplate. 
  - helm charts we want argocd to manage for this app go under dependencies in `Chart.yaml`

- a set of `*values.yaml` files
  - these define the default values for the chart and chart dependencies

- (optional) set of files under `templates/`
  - for defining extra kubernetes resources using helm templating


## Making version updates

To make version updates, edit the `Chart.yaml` under `charts/.../<name-of-chart>
dependency charts `versions` can be changed from here. 

Make sure to test version updates by using a test cluster - see [Best Practices](./BEST_PRACTICES.md)
Also make sure to bump the version in `Chart.yaml` as well

you can find the repo url by doing a `helm repo list` if you've got it installed, similarly `helm search repo <repo-name>` to get chart names and latest version available

## Deploying a new app, or modifying an existing app

## 1a. Make a branch for your changes

Create a branch for development off of `main` for making changes


## 1b. (Alternatively) making a fork for your changes 

You can alternatively decide to make a fork


## 2. Adding a new chart to manage

Clone your this repo/fork and/or checkout your new branch 

If you're adding a new chart to manage, you will need to create a new entry under `charts` directory. 

**if its an infra chart:** - add a directory under `charts/infra/<chart-name>`
**if its an app chart:** - add a directory under `charts/app/<chart-name>`

- create a boilerplate `Chart.yaml` 

```
# Chart.yaml

apiVersion: v2
name: <name-of-your-app>-apps
version: 1.0.0
dependencies:
  # put your chart dependecies here - usually the thing you want to install
  - name: <name of chart>
    version: <chart version>
    repository: <url to install the chart from>
```

- create `*values.yaml` files to act as default values under this directory
- (optional) create helm template files for extra kubernetes resources under `templates/` subdirectory (if needed)

## 3. Add references to default filepaths 

Any `*values.yaml` files you've added must be referenced by either the `argocd-apps` chart or `argocd-infra` chart (depending on whether the chart is classed as an `app` or `infra`)

*if its an infra chart* - modify `charts/argocd-infra/values.yaml`. 
*if its an app chart* - modify `charts/argocd-apps/values.yaml`

in both cases, you will need to add your new chart under `valueFiles`. e.g. adding an `infra` chart called `new-chart`:

```
...

valueFiles:
    # name of new chart
    new-chart:
    # a set of filepaths containing default helm values 
    - charts/infra/new-chart/values.yaml
    - charts/infra/new-chart/other-values.yaml
```

## 3. Document pre-/post-deployment steps 

either in: 
    - [DEPLOYING_APPS.md](./DEPLOYING_APPS.md) for app charts 
    - [DEPLOYING_INFRA](./DEPLOYING_INFRA.md) for infra charts


## 4. Test your changes by deploying a cluster

see [BEST_PRACTICES](./BEST_PRACTICES.md) on how to deploy a test cluster. 
Enable your new app/infra on this cluster. 

### 5. Delete your testing cluster 

Once the changes have been tested and you can see that argocd is managing the new chart properly, delete your test cluster

### 5. Once happy, make a Draft PR and get it merged

Make a PR to add your new cluster config so it can be tracked in `main`. Get someone to review your changes - they should spin up a test cluster themselves using your branch

Once everyone is happy make one final commit (**THIS WILL LIKELY MAKE YOUR CLUSTER GO OUT-OF-SYNC**):

**If using a branch:**

**make a commit that:** changes the `global.spec.source.targetRevision` in `clusters/<your-cluster-name>/infra-values.yaml` back to `main`

**If using a fork:**

**make a commit that:** changes the `global.spec.source.repoURL` in `clusters/<your-cluster-name>/infra-values.yaml` back to `https://github.com/stfc/cloud-deployed-apps.git`


Once the PR is merged, to keep your cluster tracking properly. Redo steps 6-8 using `https://github.com/stfc/cloud-deployed-apps.git` repo checking out `main`
