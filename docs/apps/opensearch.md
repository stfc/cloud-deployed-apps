# Opensearch Setup

OpenSearch is an open-source search and observability suite for storing unstructured data. 
It can be used to store and analyse logs k8s for instance. See https://opensearch.org/docs/latest/about/

## Prerequisites

### Storage
We've tested OpenSearch using `longhorn` as default storage - for quick install, ensure longhorn is deployed and available to use. Other storage classes are available and should work - but these haven't been tested

### Ingress
For Opensearch and Opensearch Dashboards to be accessible outside the cluster - we recommend using nginx ingress. Make sure its enabled on your cluster

## Defining action_groups, tenants, users, roles and role-mappings

You can setup action_groups, tenants, users, roles and role-mappings using this helm chart. This chart automatically builds the YAML configuration files that OpenSearch security plugin uses. See chart values.yaml for examples

## Configuring DNS + cert

To configure DNS name for OpenSearch + OpenSearch Dashboards you can add cluster-specific ingress specification. See below for example

We utilise cert-manager by default for managing certs - and you can see [cert-manager config](./misc.md) on how to configure it to use self-signed or letsencrypt verified certs

```yaml
# for access to opensearch dashboards
dashboards:
  ingress:
    annotations:
      cert-manager.io/cluster-issuer: self-signed # le-staging, le-prod for let's encrypt
    hosts:
      - host: dashboards.dev.nubes.stfc.ac.uk
        paths:
          - path: /
            pathType: ImplementationSpecific
    tls:
      - secretName: opensearch-tls
        hosts:
          - dashboards.dev.nubes.stfc.ac.uk


# for access to opensearch nodes
ingress:
  annotations:
    cert-manager.io/cluster-issuer: self-signed # le-staging, le-prod for let's encrypt
  hosts:
    - host: nodes.dev.nubes.stfc.ac.uk
      paths:
        - path: /
          pathType: ImplementationSpecific
  tls:
    - secretName: opensearch-tls
      hosts:
        - nodes.dev.nubes.stfc.ac.uk
```

## Pre-deployment steps

### 1a. Create Sops Secret (If using ArgoCD)

OpenSearch requires an initial `admin` user to be setup. This is so Opensearch Dashboards and talk to nodes in the cluster. 
You need to provide a username and password. 
  - You will need to also provide the correct bcrypt hash for the `admin` user password - so you can login to the cluster as admin 
  - You can use [this website](https://bcrypt.online/?plain_text=admin&cost_factor=12) to get a hash of your password (default cost-factor is 12)

Additionally, if you choose to use Single Sign On (SSO) via IRIS-IAM authentication - you'll need to provide the client-id and secret. Make sure you enable iris-iam authentication by setting `openid.enabled` to `true`

You can set these secrets using `sops` - template yaml files for setting these secrets can be found in `secret-templates`. See [secrets](../secrets.md) on how to set and encrypt these secrets using sops

### 1b. Set Secrets in sops (If not using ArgoCD)

You'll need to configure admin/IRIS-IAM credentials manually using the template yaml files. Copy these files to tmp directory to avoid committing secrets

```bash
cp charts/$env/$chartName/secret-templates/* /tmp/secret-templates
```

## Deployment 

You can deploy the chart as standalone

```bash
cd cloud-deployed-apps/charts/dev/opensearch
helm dependency upgrade .
helm install my-opensearch-service . -n opensearch-system  --create-namespace -f /tmp/secret-templates/opensearch.yaml
```

or you can use argocd to install it - see [Deploying Apps](../deploying-apps.md)
