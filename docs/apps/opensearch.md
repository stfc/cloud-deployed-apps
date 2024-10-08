# Opensearch Setup

OpenSearch is an open-source search and observability suite for storing unstructured data. 
It can be used to store and analyse logs k8s for instance. See https://opensearch.org/docs/latest/about/

## Prerequisites

### Storage
We've tested OpenSearch using `longhorn` as default storage - for quick install, ensure longhorn is deployed and available to use. Other storage classes are available and should work - but these haven't been tested

### Ingress
For Opensearch and Opensearch Dashboards to be accessible outside the cluster - we recommend using nginx ingress. Make sure its enabled on your cluster

## Security Configuration

OpenSearch config needs to be set in a yaml file secret. Create a `security-config.yaml` file like so:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: opensearch-securityconfig-secret
type: Opaque
stringData:
      # creating internal users https://opensearch.org/docs/latest/security/access-control/users-roles/#defining-users
      internal_users.yml: |-
        _meta:
          type: "internalusers"
          config_version: 2
        admin:
          hash: "<put bycrpt hash of password here>"
          reserved: true
          backend_roles:
          - "admin"
          description: "Demo admin user"
      
      # mapping roles to users https://opensearch.org/docs/latest/security/access-control/users-roles/#mapping-users-to-roles
      # IAM groups can also be mapped to roles
      roles_mapping.yml: |-
        _meta:
          type: "rolesmapping"
          config_version: 2
        all_access:
          reserved: false
          backend_roles:
          - "admin"
          - "stfc-cloud/admins"
          description: "Maps admin to all_access"
        own_index:
          reserved: false
          users:
          - "*"
          description: "Allow full access to an index named like the username"
      
      # https://opensearch.org/docs/latest/security/access-control/users-roles/#defining-roles
      roles.yml: |-

      # opensearch security plugin confg https://opensearch.org/docs/latest/security/configuration/index/
      # If you're using IRIS IAM copy this exactly
      config.yml: |-
        _meta:
          type: "config"
          config_version: "2"
        config:
          dynamic:
            http:
              anonymous_auth_enabled: false
            authc:
              basic_internal_auth_domain:
                description: "Authenticate via HTTP Basic against Internal Users Database"
                http_enabled: true
                transport_enabled: true
                order: "1"
                http_authenticator:
                  type: basic
                  challenge: false
                authentication_backend:
                  type: intern
              openid_auth_domain:
                http_enabled: true
                transport_enabled: true
                order: 2
                http_authenticator:
                  type: openid
                  challenge: false
                  config:
                    subject_key: preferred_username
                    roles_key: groups
                    openid_connect_url: "https://iris-iam.stfc.ac.uk/.well-known/openid-configuration"
                    enable_ssl: true
                    verify_hostnames: true
                authentication_backend:
                  type: noop
```

in `config.yml` - we're setting up IRIS-IAM and basic username/password as 2 possible methods for authentication - alter this to suit your requirements

You'll need to setup users, roles and rolebindings here in the appropriate files. We cannot use CRDs for defining these whilst also setting up oidc 

You will also need to create a Kubernetes Secret containing admin credentials (encoded in base64) PLEASE CHANGE THE PASSWORD FROM ADMIN:

```bash
kubectl create secret generic opensearch-admin-credentials
--from-literal=username='admin' 
--from-literal=password='admin'
-n opensearch-system 
```

NOTE: This password must produce the correct bcrpyt hash that is saved in `security-config.yaml`

## Defining users, roles and role-mappings

NOTE: opensearch k8s operator CRDs currently are incompatible with using security-config.yaml. So use security-config.yaml for defining users

NOTE: once CRDs are compatible with security-config.yaml or if an alternative way to define IAM config is made available - we cannot manage users/roles/rolemappings using GitOps 


## Configuring IRIS IAM Setup

We're using OpenSearch's inbuilt oidc capabilities to configure authentication via IRIS IAM. 

Any IRIS IAM `groups` that a user belongs to gets mapped to a `backend_role` with the same name - we can then define any `role_mappings` to map that IAM group to a `role` in OpenSearch    

Example - mapping `stfc-cloud/admins` group to the admin role:
```yaml
roleMappings:
- roleName: all_access
  backend_roles: 
    - stfc-cloud/admins
```

## Configuring DNS + cert

To configure DNS name for OpenSearch + OpenSearch Dashboards you can add cluster-specific ingress specification. See below for example

We utilise cert-manager by default for managing certs - and you can see [cert-manager config](./misc.md) on how to configure it to use self-signed or letsencrypt verified certs

```yaml

# for access to opensearch dashboards
dashboards:
  ingress:
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

### 1. Create Secret for IAM Credentials

Create a secret for IAM credentials you can do so by creating a file in `/tmp/iam-secret.yaml` and adding this config:

```yaml
apiVersion: v1
data:
  client-id: "" # put client id here - remember to encode it in base64
  client-secret: "" # put client secret here - remember to encode it in base64
kind: Secret
metadata:
  name: iris-iam-credentials
  namespace: galaxy # make sure this matches namespace galaxy will be installed in 
type: Opaque
```	

### 2. Create Secrets for "admin" user and any other defined users

see above - Defining users, roles and role-mappings

NOTE: you will need to create one for admin even if you haven't defined any other users

### 3. Create Secret for security-config.yaml

see above - Security Configuration

## Deployment 

You can deploy the chart as standalone

```bash
cd cloud-deployed-apps/charts/dev/opensearch
helm dependency upgrade .
helm install my-opensearch-service . -n opensearch-system  --create-namespace
```

or you can use argocd to install it - see [Deploying Apps](../deploying-apps.md)
