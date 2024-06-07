# Kubernetes Deployed Apps using ArgoCD for the STFC Cloud 

A collection of helm charts and configuration files for setting up clusters that are being used by the STFC Cloud team. 

This repo acts as the "central repository" of all configuration information for our K8s clusters. It allows a user to select which applications or infrastructure they want to deploy, from a pre-opinionated list.

We use ArgoCD to manage our clusters. Each cluster has its own argocd deployment that uses this repo as its source of truth

# Quick Start

These links assume you have existing clusters or applications to deploy within the repository. If you want to setup a cluster from scratch, you'll need to define a new cluster from the below links first:

### Step-by-step-guides
- [Deploying a new cluster](docs/clusters.md)
- [Adding a new chart to this repo](docs/charts.md)
- [Deploying a chart onto a cluster](docs/deploying-apps.md)


### More information
- [How it works - folder-based flow & promotion flowchart](docs/folder-based-flow.md)
- [Deploying secrets](docs/secrets.md)  


# Repository Structure

This repository contains the following directories:

- `charts` - Described in the [charts documentation](docs/charts.md), this directory contains all the helm charts and generic configuration that are used to deploy applications and infrastructure to multiple clusters.

- `clusters` - This directory contains cluster-specific compositions of applications and infrastructure. For example, it may contain definitions of a production cluster, the flavors used and the applications deployed onto it. The overrides allow us to have different configurations for each clusters, or point to different repository revisions. Clusters are sub-divided into the environment they belong to (i.e. dev, staging, production).

- `scripts` - This directory contains various "helper" scripts that we use for handling configuration management aspects
