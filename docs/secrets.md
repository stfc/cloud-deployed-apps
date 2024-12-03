# Secrets

## Overview
Secrets are handled by SOPS, this breaks the chicken-egg problem of installing a secret to access secrets on vault...etc.
age is used to encrypt the secrets, and helm-secrets is used to decrypt them within ArgoCD

## Setup
- Install SOPS: https://github.com/getsops/sops
- Install age: https://github.com/FiloSottile/age or apt-get install age for 22.04+
- Generate a personal private key for age:

```bash
mkdir -p ~/.config/sops/age
age-keygen >> ~/.config/sops/age/keys.txt
```

- (Optional) set your preferred editor, e.g.
```bash
export EDITOR="code --wait"
```

## App and Infra Secrets

An "infra" secret refers to any secrets that is used by the management cluster to spin up child clusters - this is usually secrets related to CAPI/azimuth charts. An "app" secret refers to any other type  

"Infra" secrets must only be accessed by that environment's management cluster - not even the child cluster it pertains to
    - Infra secrets for each cluster are mandatory 

"App" secrets must only be accessed by the cluster the app is running on
    - App secrets are optional - see app-specific docs to see if defining a secret is required


## Adding a new secret

The .sops.yaml file is used to specify which public keys get automatically associated with the encrypted file. 
Note: You do not need access to a private key to encrypt a file, only to decrypt it. This means secrets can be added for prod write-only.

For example: to add an infra-related secret for dev management cluster:

- Add yours to the relevant sections in `secrets/dev/management/infra/.sops.yaml`
- Add or edit your secret as follows:

```bash
cd secrets/dev/management/infra/  # Currently we have to be in the same dir
sops example-secret.yaml
```

> [!NOTE]
> shared secrets (used by all clusters) in the environment go in `_shared` folder
> These must be accessible by all clusters - so remember to add all cluster temp keys to `.sops.yaml`  

## Using App Secrets

If a chart requires a secret - a template file for how the secret file should look will be provided in `charts/<environment>/<chartname>/secrets-templates/` 

1. Make sure you can access the cluster secrets you want to run the chart on
   - check if your age key is in `.sops.yaml` for that cluster
   - if not - add your key
   - it's a good idea to get someone with access to add your public key and run `sops updatekeys` on all other secret files in the directory and make a PR first

2. Copy the template file into `tmp` folder (or somewhere not in this repo - to minimise risk of accidentally pushing a sensitive info)

3. Fill out the secret template file

4. Encrypt and save the file using 

```
sops -e /tmp/<filename> -o <path-to-repo>/secrets/apps/<environment>/<clustername>/<filename>.yaml
```

5. Add to your apps.yaml an extra line in the Appset list generator to point to your secrets file. 

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: management-apps
  namespace: argocd
spec:
  generators:
    - list:
        ...

        - name: my-new-app
          chartName: chart-with-secret
          namespace: default
          valuesFile: ../../../clusters/dev/management/my-app-values
          # ADD THIS LINE BELOW - change the path to match your secrets file location
          secretsFile: ../../../secrets/apps/dev/my-app.yaml
```

## ArgoCD Integration

ArgoCD needs access to the private key to decrypt the secrets. This is done by adding the private key to the ArgoCD application as a secret:

You can use the bash script in `./scripts/deploy-helm-secret.sh` to deploy an age private key onto a cluster. 

```bash
kubectl -n argocd create secret generic helm-secrets-private-keys --from-file=key.txt=age-key.txt
```


## VSCode integration

An extension exists for SOPS for vscode that will automatically decrypt/encrypt files. 

You can find it here: https://github.com/signageos/vscode-sops
