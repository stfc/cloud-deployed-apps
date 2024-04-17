# Deploying ArgoCD and apps onto a Worker Cluster

### In this doc there will be the steps needed to deploy ArgoCD and apps onto a worker cluster.
(This doc assumed you've completed all the steps in [Deploying a new cluster](DeployNewCluster.md))

# Confirming ArgoCD works
The final step of the previous doc:
### 9. Deploy ArgoCD onto your new cluster

9a. From the VM you have copied the kubeconfig onto you need to clone into the repo and switch to your branch

```
git clone https://github.com/stfc/cloud-deployed-apps.git
cd cloud-deployed-apps
git switch <your-branch>
```
9b. Deploy argoCD onto your cluster with the script

```
cd scripts
./deploy.sh <your-cluster-name>
```

### From here you should have an ArgoCD instance and a copy of the branch you are developing in
> [!TIP]
> You can check if argoCD ingress has started with `kubectl get ingress -A`, and look for an 'argocd-server'

> [!NOTE]  
> Pay attention to Step 6 in [Deploying a new cluster](DeployNewCluster.md) for setting a local dns

#### This should allow you to visit your ArgoCD instance at the address mentioned in argocd-values.yaml

---
# Deploying apps

## 1. App chart creation

You will need to create some new files and a directory for them in charts

Ensure you are in the home of the directory where your git branch is in this scenario it is `~/cloud-reployed-apps/`

Create a directory for your app `mkdir charts/apps/<app-name>`

Create a chart yaml and a values yaml
```
touch charts/apps/<app-name>/Chart.yaml
touch charts/apps/<app-name>/values.yaml
```

## 2. Content of Chart.yaml
The app-chart-repository is the location where the helm chart is hosted
```
apiVersion: v2
name: <app-name>
version: 1.0.0
dependencies:
- name: <app-name>
  repository: <app-chart-repository>
```

## 3. values.yaml

The values.yaml file should hold the regular values that you would pass when running the helm install

## 4. Changes to the app-values.yaml file

The app-values.yaml file in your cluster needs to be edited to include the app

In `clusters/<cluster-name>/app-values.yaml` there will be something like
```
global:
  ### name of the cluster 
  ### MUST MATCH THE DIRECTORY NAME
  
  clusterName: <your-cluster-name> #Same as in step 2

  spec:
    source:
      targetRevision: `<your-branch>`

      # change this if you're using a fork
      repoURL: https://github.com/stfc/cloud-deployed-apps.git 

      # namespace where the argocd applications will be installed to 
      namespace: argocd
```

Added to this file you will have to fill in the following fields:
```
apps:
  #below is an example of how to specify an app
  #name of the argocd application
- name: "app"
  
  #when true, will disable auto-sync and auto-heal on the argocd app
  disableAutomated: false 
 
   #name of the chart to install - corresponds with chart name in charts/apps/
  chartName: argocd
 
   #namespace where the chart contents will be installed to
  namespace: argocd
 
   #(optional) can define the git SHA to sync against specific to the app
   #This overrides global.spec.targetRevision
  targetRevision: main
```

## 5. Applying changes

As we are running in a branch, anytime you want to test a change on the apps in the cluster, you just have to push the changes to your remote branch

```
git add . 
git commit
git push
```
### Effectively creating your development environment within the branch