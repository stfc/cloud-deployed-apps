# STFC Cloud GitOps Repo

This repo is our GitOps repository which we use to manage the various Cloud services we run on Kubernetes. We use ArgoCD to manage the deployment of our services

Our charts are hosted here: [cloud-helm-charts](https://github.com/stfc/cloud-helm-charts.git).

### How does this repo work?
See [Overview](overview.md)

### How to setup GitOps using this repo?
See [Setup Steps](infra-setup.md)

### Configuring ArgoCD?
See [ArgoCD Setup](argocd.md)

### Deploying Secrets?
Whether deploying from scratch or need to update secrets, see [Deploying Secrets](secrets.md)

### New to the ArgoCD, GitOps and Folder-flows structure?

**Start with:** [Our folder-based flow & promotion flowchart](folder-based-flow.md)

[ArgoCD Docs](https://argo-cd.readthedocs.io/en/stable/)

