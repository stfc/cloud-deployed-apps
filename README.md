# Kubernetes Deployed Apps using ArgoCD for the STFC Cloud 

A collection of helm charts and configuration files for setting up clusters that are being used by the STFC Cloud team. 

This repo acts as the "central repository" of all configuration information for our K8s clusters. 

We use ArgoCD to manage our clusters and each cluster, each cluster has it's own ArgoCD microservice which syncs against this repo

#
# Quick Start
- [Setting up a cluster using this repo](docs/DEPLOYING_CLUSTER.md)
- [Setting up a chart to be managed in this repo](docs/MODIFYING_CHARTS.md)

- [Deploying infrastructure to a cluster](docs/DEPLOYING_INFRA.md) 
- [Deploying apps to a cluster](docs/DEPLOYING_APPS.md)
  
- [Best Practices](docs/BEST_PRACTICES.md)


#
# Repository Structure

This repository contains the following directories:

- `charts` - Holds helm charts that we want argoCD to spin up and manage. This includes
  - `argocd` - which deploys `argo-cd` helm chart.

  - `argocd-apps` - which deploys an argocd application resource for each app that we want argocd to manage for the cluster. It also deploys `cloud-deployed-apps` argocd application that keeps track of this repo for any changes made to default or cluster-specific values

  - `argocd-infra` - this is the same as `argocd-apps` but for infra that we want argocd to manage
  
  - Other Charts are organised into `apps` and `infra`. Charts in `apps` directory are system-agnostic charts that can be installed on any kubernetes cluster. Charts in `infra` are charts that are dependent on specific flavor of kubernetes - such as CAPI deployed clusters. Each Chart contains "default" configuration files for each - usually a set of `yaml` files. 

- `clusters` - This directory contains cluster-specific values and patch files. These values override the "default" values allowing us to have slightly different configurations on our clusters - such as having different production and staging clusters 

- `scripts` - This directory contains various "helper" scripts that we might use for cluster management

