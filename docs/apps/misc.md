This section details how to deploy cluster dependencies like argocd and cert-manager

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


# Cert-manager Setup

Cert-manager is a tool we use to manage certs.

Our chart configures cert-manager and includes pre-configured issuers including staging and production letsencrypt - to enable you to setup verified HTTPS certs for your web-apps

## Pre-deployment steps

### (Optional) 1. Enable letsencrypt issuers 

to enable letsecrypt issuers, you need to add:

```yaml
cert-manager:
  
  # for testing your networing - PLEASE USE THIS TO TEST FIRST! 
  # this will prevent the ENTIRE department getting rate-limited!
  le-staging:  
    enabled: true

  # prod issuer
  le-prod:
    enabled: true
```

## Configuration 

To enable letsencrypt issuer - you need to add an annotation to ingress resources and enable tls

> [!CAUTION]
> This is just an example - read the documentation on the helm chart your trying to install to see how to configure nginx ingress. 
> You might need to make your own - see [Ingress Controller Docs](https://kubernetes.io/docs/concepts/services-networking/ingress/) 

```yaml
ingress:
  annotations:
    # add the annotation
    cert-manager.io/cluster-issuer: "letsencrypt-prod" # or letsencrypt-staging or self-signed
    hosts:
      - name: myservice.example.com
        path: /
        port: http
    # specify tls and secret name
    tls:
      - secretName: my-le-cert
        hosts:
          - myservice.example.com
```

