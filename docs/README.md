# Deploying Apps using ArgoCD for STFC Cloud

This documentation outlines how to set up clusters managed by ArgoCD in the STFC Cloud.

## Quick Start

## Looking to Deploy and Setup an App?

- [ArgoCD Setup](apps/argocd.md)
- [Cert-manager](apps/cert-manager.md)
- [Storage - Manila or Longhorn](apps/storage.md)
- [Galaxy](apps/galaxy.md) (IN DEVELOPMENT)
- Victoria Metrics (DOCS NEEDED) 

### New to the ArgoCD folder workflow used? 

**Start with:** [How it works - folder-based flow & promotion flowchart](folder-based-flow.md)

### Deploying a New ArgoCD Environment?
If you are starting from scratch and need to set up a new environment (e.g. deploying a new dev ArgoCD cluster), start with: [Deploying a new cluster](clusters.md)

> [!NOTE]
> This guide assumes you already have a CAPI cluster already deployed to configure into a new ArgoCD environment.

### Need to Deploy Secrets?
Whether deploying from scratch or need to update secrets, see [Deploying Secrets](secrets.md)

### Add a New Cluster to an Existing ArgoCD Environment?
For new clusters being added to an existing environment to be managed through ArgoCD, see: [Deploying Child Clusters](child-clusters.md)

### Adding a New Chart to this Repository?
See [Adding a New Chart to This Repo](charts.md)

### Deploying a Chart onto a Cluster?
See [Deploying a Chart Onto a Cluster](deploying-apps.md)

### Need to Set Up Longhorn App?
See [App Setup Steps](app-setup.md)

### Need to Set Up Specific Infra?
See [Infra Setup Steps](infra-setup.md)