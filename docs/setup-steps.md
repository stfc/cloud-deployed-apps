# Setup Steps

> [!NOTE]
> This document details how to deploy ArgoCD onto our cluster.
> These are disaster recovery docs 


# Prerequisites

1. For each environment (`staging` or `prod`) you're setting up you'll need to deploy a CAPI cluster see [our docs](https://stfc.atlassian.net/wiki/spaces/CLOUDKB/pages/211878034/Cluster+API+Setup)

> [!NOTE]
> you must name this `staging-management` or `prod-management` depending on if your deploying `staging` or `prod`
> These are disaster recovery docs 


2. Access age private key for the environment from Keeper (or equivalent secrets management tool) for the environment you're setting up 


# Steps

> [!NOTE]
> These steps assumes you're setting up `staging`, it would be the same process for `prod` 


1.  Rotate the application credential of the clusters you're deploying. 

- login as as the k8s service account

- create a new application credential, copy its contents and replace it under:
  
- `clusters/staging/management/secrets/infra/app-creds.yaml`
- `clusters/staging/worker/secrets/infra/app-creds.yaml`

```yaml
stfc-cloud-openstack-cluster:
    ## PLACE YOUR APP-CRED HERE
    clouds:
        openstack:
            auth:
                auth_url: https://openstack.stfc.ac.uk:5000
                application_credential_id: foo
                application_credential_secret: bar
                project_id: biz
            region_name: baz
            interface: public
            identity_api_version: 3
            auth_type: v3applicationcredential
```

AND REMEMBER TO ENCRYPT EACH FILE WITH SOPS!

2. (Optional) If setting up from scratch, you may also want to setup fresh Floating IPs for each cluster

- You need to provision 4 (API-server and Ingress for both `management` and `worker`) and change mentions of them.

For `api-server` floating ip for `management`, update `clusters/staging/management/secrets/infra/api-server-fip.yaml` with:

```yaml
stfc-cloud-openstack-cluster:
    openstack-cluster:
        apiServer:
            floatingIP: 130.246.xxx.xxx # your ip here
```

For `api-server` floating ip for `worker`, update `clusters/staging/workwer/secrets/infra/api-server-fip.yaml` with:

```yaml
stfc-cloud-openstack-cluster:
    openstack-cluster:
        apiServer:
            floatingIP: 130.246.xxx.xxx # your ip here
```

AND REMEMBER TO ENCRYPT EACH FILE WITH SOPS!

To update ingress IPs, they are located in: 

- `clusters/staging/management/infra-values.yaml`
- `clusters/staging/worker/infra-values.yaml`

under yaml path: `addons.ingress.nginx.release.values.service.loadBalancerIP`

> [!NOTE]
> Remember to commit these changes and merge this into `main` before proceeding

> [!NOTE]
> If you're replacing ingress Floating IPS, you'll need to update DNS records accordinly 

3. Make sure you've got a local version of the `staging` private age key stored in `.config/sops/config/age/keys.txt` 

4. Rotate temporary key for argocd for `staging/management` cluster (and `infra` secrets) and update secrets

```bash
cd scripts/
./rotate-temp-keys.sh staging management
./update-secrets staging management
```

5. Upload the temporary management key to your management cluster 

`./deploy-helm-secret.sh /tmp/staging-age-management-key.txt`

6. Deploy argocd onto the cluster

```bash
git checkout main
./deploy.sh staging management
```

7. Once deployed, wait for all the argocd apps to deploy and for the worker cluster to be created. After a while, the Web UI should be accessible under `argocd.staging-mgmt.nubes.stfc.ac.uk` (or whatever you've set the ingress path as in `argocd-setup-values.yaml`). 

You can get the password by running: `./get-argocd-password.sh`
remember to save it in Keeper (or another secrets management software)

8. Next, get the worker cluster kubeconfig

```bash
clusterctl get kubeconfig staging-worker-cluster -n staging-worker-cluster > ~/staging-worker-cluster.kubeconfig

export KUBECONFIG="~/staging-worker-cluster.kubeconfig"
```

9. Upload the other temporary management key to your worker cluster 

`./deploy-helm-secret.sh /tmp/staging-age-worker-key.txt`

10. Deploy argocd onto the cluster

```bash
./deploy.sh staging worker
```

11. Wait for apps to deploy on the worker cluster. After a while, the Web UI should be accessible under `argocd.staging-worker.nubes.stfc.ac.uk` (or whatever you've set the ingress path as in `argocd-setup-values.yaml`). 

You can again get the password by running: `./get-argocd-password.sh`
remember to save it in Keeper (or another secrets management software)

12. Wait for all apps on both clusters to become available. Clusters should then start alerting - check and resolve them accordinly.