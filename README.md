# Kubernetes Deployed Apps using ArgoCD for the STFC Cloud 

A collection of helm charts and configuration files for setting up clusters that are being used by the STFC Cloud team. 

This repo acts as the "central repository" of all configuration information for our K8s clusters. It allows a user to select which applications or infrastructure they want to deploy, from a pre-opinionated list.

We use ArgoCD to manage our clusters and each cluster, each cluster has its own ArgoCD microservice which syncs against this repo

# Quick Start

These links assume you have existing clusters or applications to deploy within the repository. If you want to setup a cluster from scratch, you'll need to define a new cluster from the below links first:

### Step-by-step-guides
- [Deploying a new cluster from Management cluster](docs/DeployNewCluster.md)
- [Deploying an app onto a worker cluster](docs/DeployArgoandApps.md)

### More information
- [Deploying infrastructure to a cluster](docs/DEPLOYING_INFRA.md) 
- [Deploying apps to a cluster](docs/DEPLOYING_APPS.md)

---

- [Creating a new cluster using this repo](docs/DEPLOYING_CLUSTER.md)
- [Adding or modifying an app deployed by this repo](docs/charts.md)
  
- [More Things to know](docs/ThingsToKnow.md.md)


# Repository Structure

This repository contains the following directories:

- `charts` - Described in the [charts documentation](docs/charts.md), this directory contains all the helm charts and generic configuration that are used to deploy applications and infrastructure to multiple clusters.

- `clusters` - This directory contains cluster-specific compositions of applications and infrastructure. For example, it may contain definitions of a production cluster, the flavors used and the applications deployed onto it. The overrides allow us to have different configurations for each clusters, or point to different repository revisions.

- `scripts` - This directory contains various "helper" scripts that we use for handling configuration management aspects

