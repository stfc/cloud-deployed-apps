# Kubernetes Deployed Apps using ArgoCD for the STFC Cloud 

A collection of helm charts and configuration files for setting up clusters that are being used by the STFC Cloud team. 

This repo acts as the "central repository" of all configuration information for our K8s clusters. It allows a user to select which applications or infrastructure they want to deploy, from a pre-opinionated list.

We use ArgoCD to manage our clusters and each cluster, each cluster has its own ArgoCD microservice which syncs against this repo

# Quick Start

These links assume you have existing clusters or applications to deploy within the repository. If you want to setup a cluster from scratch, you'll need to define a new cluster from the below links first:
- [Deploying a new cluster from staging cluster](docs/DeployNewCluster.md)
- [Deploying infrastructure to a cluster](docs/DEPLOYING_INFRA.md) 
- [Deploying apps to a cluster](docs/DEPLOYING_APPS.md)

---

- [Creating a new cluster using this repo](docs/DEPLOYING_CLUSTER.md)
- [Creating a chart to be managed using this repo](docs/MODIFYING_CHARTS.md)
  
- [Best Practices](docs/BEST_PRACTICES.md)


# Repository Structure

This repository contains the following directories:

- `charts` - Holds base Helm charts for argoCD to spin up and manage. This includes
  - `argocd` - which deploys Argo CD.

  - `argocd-apps` - which deploys an argocd application resource for each Kubernetes application that we want argocd to manage for the cluster. It also syncs from the `cloud-deployed-apps` repository.

  - `argocd-infra` - this is the same as `argocd-apps` but for CAPI Infrastructure that we want argocd to manage
  
  - Other Charts are organised into `apps` and `infra`. Charts in `apps` directory are system-agnostic charts that can be installed on any kubernetes cluster. Charts in `infra` are charts that are dependent on specific flavor of kubernetes - such as CAPI deployed clusters. Each Chart contains "default" configuration files for each - usually a set of `yaml` files. 

- `clusters` - This directory contains cluster-specific compositions of applications and infrastructure. For example, it may contain definitions of a production cluster, the flavors used and the applications deployed onto it. The overrides allow us to have different configurations for each clusters, or point to different repository revisions.

- `scripts` - This directory contains various "helper" scripts that we use for handling configuration management aspects

