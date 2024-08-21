# ArgoCD Setup 

ArgoCD is what we use for enabling GitOps on our clusters - it is a Continuous delivery tool for managing applications on our clusters. 

We manage ArgoCD using ArgoCD - its just another app.

## Pre-requisites

A Kubernetes cluster - preferrably deployed using CAPI and running on the STFC CLoud

## Pre-deployment steps

Our chart configured argocd so it should just work out-of-the-box without any tweaks 

### 1. Change Domain Name
The only thing you'll definately want to change is the domain name to access the webui:

```yaml
argo-cd:
  global:
    domain: "myargocd.example.com
```

## Configuration

`argocd-setup-values.yaml` is the file we use for configuring cluster-specific argocd values and its dependencies. 

See [Argocd Helm Chart](https://github.com/argoproj/argo-helm/tree/main/charts/argo-cd) for details  

## Deployment 

see [Deploying Apps](../deploying-apps.md)


